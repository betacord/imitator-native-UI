(************************************************************
 *
 *                       IMITATOR
 *
 * Université Sorbonne Paris Nord, LIPN, CNRS, France
 * Université de Lorraine, CNRS, Inria, LORIA, Nancy, France
 *
 * Module description: PRP algorithm [ALNS15]
 *
 * File contributors : Étienne André
 * Created           : 2016/01/11
 *
 ************************************************************)


(************************************************************)
(************************************************************)
(* Modules *)
(************************************************************)
(************************************************************)
open OCamlUtilities
open ImitatorUtilities
open Exceptions
open AbstractModel
open AbstractProperty
open Result
open AlgoIMK
open State



(************************************************************)
(************************************************************)
(* Class definition *)
(************************************************************)
(************************************************************)
class algoPRP (model : AbstractModel.abstract_model) (options : Options.imitator_options) (pval : PVal.pval) (state_predicate : AbstractProperty.state_predicate) =
	object (self) inherit algoIMK model options pval (*as super*)

	(************************************************************)
	(* Class variables *)
	(************************************************************)
	(* Determines the mode of the algorithm: was a bad state already found? *)
	val mutable bad_state_found: bool = false

	(* Convex constraint ensuring unreachability of the bad states *)
	(* Parameter valuations cannot go beyond what is defined in the initial state of the model *)
	val mutable good_constraint : LinearConstraint.p_linear_constraint = (LinearConstraint.p_copy model.initial_p_constraint)

	(* Non-necessarily convex constraint ensuring reachability of at least one bad state *)
	val mutable bad_constraint : LinearConstraint.p_nnconvex_constraint = LinearConstraint.false_p_nnconvex_constraint ()


	(************************************************************)
	(* Class methods *)
	(************************************************************)

	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Name of the algorithm *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method! algorithm_name = "PRP"



	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Process a pi-compatible state *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method private process_pi0_compatible_state (state : state) =
		let to_be_added =
			(* Check whether the current location matches one of the unreachable global locations *)
			if State.match_state_predicate model state_predicate state then(

				(* Project onto the parameters *)
				let p_constraint = LinearConstraint.px_hide_nonparameters_and_collapse state.px_constraint in

				(* Projecting onto SOME parameters if required *)
				(*** BADPROG: Duplicate code (EFsynth / AlgoLoopSynth) ***)
				if Input.has_property() then(
					let abstract_property = Input.get_property() in
					match abstract_property.projection with
					(* Unchanged *)
					| None -> ()
					(* Project *)
					| Some parameters ->
						(* Print some information *)
						if verbose_mode_greater Verbose_high then
							self#print_algo_message Verbose_high "Projecting onto some of the parameters…";

						(*** TODO! do only once for all… ***)
						let all_but_projectparameters = list_diff model.parameters parameters in

						(* Eliminate other parameters *)
						LinearConstraint.p_hide_assign all_but_projectparameters p_constraint;

						(* Print some information *)
						if verbose_mode_greater Verbose_medium then(
							print_message Verbose_medium (LinearConstraint.string_of_p_linear_constraint model.variable_names p_constraint);
						);
				); (* end if projection *)

				(* Print some information *)
				self#print_algo_message Verbose_standard "Found a state violating the property.";
				if verbose_mode_greater Verbose_medium then(
					self#print_algo_message Verbose_medium "Adding the following constraint to the list of bad constraints:";
					print_message Verbose_medium (LinearConstraint.string_of_p_linear_constraint model.variable_names p_constraint);
				);

				(*** NOTE: not copy paste (actually, to copy when EFsynth will be improved with non-convex constraints) ***)
				LinearConstraint.p_nnconvex_p_union_assign bad_constraint p_constraint;

				if verbose_mode_greater Verbose_low then(
					self#print_algo_message_newline Verbose_low ("Kbad now equal to:");
					print_message Verbose_low (LinearConstraint.string_of_p_nnconvex_constraint model.variable_names bad_constraint);
				);

				(* PRP switches to bad-state algorithm *)
				if not bad_state_found then(
					(* Print some information *)
					self#print_algo_message Verbose_standard "Switching to EFsynth-like algorithm";
				);
				bad_state_found <- true;

				(* Do NOT compute its successors *)
				false

			)else(
				self#print_algo_message Verbose_medium "State not corresponding to the one wanted.";

				(* Keep the state as it is not a bad state *)
				true
			)

		in

		(* Return result *)
		to_be_added


	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(* Add a new state to the state space (if indeed needed) *)
	(* Return true if the state is not discarded by the algorithm, i.e., if it is either added OR was already present before *)
	(* Can raise an exception TerminateAnalysis to lead to an immediate termination *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(*** TODO: return the list of actually added states ***)
	(*** WARNING/BADPROG: the following is partially copy/paste from AlgoEFsynth.ml and AlgoPRP.ml***)
	(*** TODO: factorize ***)
	method! add_a_new_state source_state_index combined_transition new_state =
		(* Test pi0-compatibility *)
		let pi0compatible = self#check_pi0compatibility new_state.px_constraint in

		(* Print some information *)
		if verbose_mode_greater Verbose_high then(
			(* Means state was not compatible *)
			if not pi0compatible then(
				if verbose_mode_greater Verbose_high then
					self#print_algo_message Verbose_high ("The pi-incompatible state had been computed through action '" ^ (model.action_names (StateSpace.get_action_from_combined_transition model combined_transition)) ^ "', and was:\n" ^ (ModelPrinter.string_of_state model new_state));
			);
		);

		(* Only add the new state if it is pi0-compatible *)
		(*** NOTE: this is a key principle of PRP to NOT explore pi0-incompatible states ***)
		if pi0compatible then (

			(* Try to add the new state to the state space *)
			let addition_result = state_space#add_state options#comparison_operator model.global_time_clock new_state in

			begin
			match addition_result with
			(* If the state was present: do nothing *)
			| StateSpace.State_already_present _ -> ()
			(* If this is really a new state, or a state larger than a former state *)
			| StateSpace.New_state new_state_index | StateSpace.State_replacing new_state_index ->

				(* First check whether this is a bad tile according to the property and the nature of the state *)
				self#update_statespace_nature new_state;

				(* Will the state be added to the list of new states (the successors of which will be computed)? *)
				let to_be_added = self#process_pi0_compatible_state new_state in

				(* Add the state_index to the list of new states (used to compute their successors at the next iteration) *)
				if to_be_added then
					new_states_indexes <- new_state_index :: new_states_indexes;

			end (* end if new state *)
			;

			(*** TODO: move the rest to a higher level function? (post_from_one_state?) ***)

			(* Update the transitions *)
			self#add_transition_to_state_space (source_state_index, combined_transition, (*** HACK ***) match addition_result with | StateSpace.State_already_present new_state_index | StateSpace.New_state new_state_index | StateSpace.State_replacing new_state_index -> new_state_index) addition_result;

		); (* end if valid new state *)

		(* The state is kept only if pi-compatible *)
		pi0compatible
	(*** END WARNING/BADPROG: what precedes is almost entirely copy/paste from AlgoEFsynth.ml ***)


	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Actions to perform with the initial state; returns None unless the initial state cannot be kept, in which case the algorithm returns an imitator_result *)
	(*** NOTE: this function is redefined here ***)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method! try_termination_at_initial_state : Result.imitator_result option =
		(* Retrieve the initial state *)
		let initial_px_constraint : LinearConstraint.px_linear_constraint = self#get_initial_px_constraint_or_die in
		let initial_state : State.state = {global_location = model.initial_location ; px_constraint = initial_px_constraint} in

		(*** NOTE: the addition of neg J to all reached states is performed as a side effect inside the following function ***)
		(*** BADPROG: same reason ***)
		let pi0_compatible = self#check_pi0compatibility initial_px_constraint in

		if pi0_compatible then None
		else(
			(*(* Set termination status *)
			termination_status <- Some (Result.Regular_termination);

			(* Terminate *)
			Some (self#compute_result)*)
			(*** TODO: recheck! (2022/10/07) ***)
			let _ = self#process_pi0_compatible_state initial_state in None
		)


(*	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Actions to perform with the initial state; returns true unless the initial state cannot be kept (in which case the algorithm will stop immediately) *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method process_initial_state initial_state =
		(* Get the constraint *)
		let initial_constraint = initial_state.px_constraint in

		(*** NOTE: the addition of neg J to all reached states is performed as a side effect inside the following function ***)
		(*** BADPROG: same reason ***)
		let pi0_compatible = self#check_pi0compatibility initial_constraint in

		if not pi0_compatible then(
			(* Discard *)
			false
		)else(
			(* Run analysis to check the property, and decide whether the state should be kept or not) *)
			self#process_pi0_compatible_state initial_state
		)*)


	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Actions to perform when meeting a state with no successors: nothing to do for this algorithm *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method! process_deadlock_state _ = ()


	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(* Should we process a pi-incompatible inequality? *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method! process_pi_incompatible_states () =
		(* Only explore if no bad states found *)
		let answer = not bad_state_found in
		(* Print some information *)
		self#print_algo_message Verbose_medium ("Exploring pi-incompatible state? " ^ (string_of_bool answer));
		(* Return *)
		answer


	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Actions to perform when a pi-incompatible inequality is found. Add its negation to the accumulated good constraint. *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method! process_negated_incompatible_inequality negated_inequality =
		self#print_algo_message_newline Verbose_medium ("Adding the negation of a pi-incompatible inequality to Kgood.\n");

		let negated_constraint = LinearConstraint.make_p_constraint [negated_inequality] in

		LinearConstraint.p_intersection_assign good_constraint [negated_constraint];

		if verbose_mode_greater Verbose_low then(
			self#print_algo_message_newline Verbose_low ("Kgood now equal to:");
			print_message Verbose_low (LinearConstraint.string_of_p_linear_constraint model.variable_names good_constraint);
		);
		()


	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Actions to perform at the end of the computation of the *successors* of post^n (i.e., when this method is called, the successors were just computed). Nothing to do for this algorithm. *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method! process_post_n (_ : State.state_index list) = ()


	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Method packaging the result output by the algorithm *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method! compute_result =

		let result = if bad_state_found then(
			(* Return Kbad *)
			bad_constraint
		)else(
			(* Return Kgood *)
			LinearConstraint.p_nnconvex_constraint_of_p_linear_constraint good_constraint
		)
		in

		self#print_algo_message_newline Verbose_standard (
			"Successfully terminated " ^ (after_seconds ()) ^ "."
		);

		(* Get the termination status *)
		 let termination_status = match termination_status with
			| None -> raise (InternalError "Termination status not set in PRP.compute_result")
			| Some status -> status
		in

		(* The state space nature is good if 1) it is not bad, and 2) the analysis terminated normally;
			It is bad if any bad state was met. *)
		let statespace_nature =
			if statespace_nature = StateSpace.Unknown && termination_status = Regular_termination then StateSpace.Good
			(* Otherwise: unchanged *)
			else statespace_nature
		in

		(* Constraint is... *)
		let soundness =
			(* EXACT if termination is normal, whatever the state space nature is *)
			if termination_status = Regular_termination then Constraint_exact
			(* POSSIBLY UNDERAPPROXIMATED if state space nature is bad and termination is not normal *)
			else if statespace_nature = StateSpace.Bad then Constraint_maybe_under
			(* INVALID if state space nature is good and termination is not normal *)
			else Constraint_maybe_invalid
		in

		let result = match statespace_nature with
			| StateSpace.Good | StateSpace.Unknown -> Good_constraint(result, soundness)
			| StateSpace.Bad -> Bad_constraint(result, soundness)
		in

		(* Return result *)
		Point_based_result
		{
			(* Reference valuation *)
			reference_val		= self#get_reference_pval;

			(* Result of the algorithm *)
			result				= result;

			(* Explored state space *)
			state_space			= state_space;

			(* Total computation time of the algorithm *)
			computation_time	= time_from start_time;

			(* Termination *)
			termination			= termination_status;
		}


(************************************************************)
(************************************************************)
end;;
(************************************************************)
(************************************************************)
