(************************************************************
 *
 *                       IMITATOR
 * 
 * Université Paris 13, LIPN, CNRS, France
 * Université de Lorraine, CNRS, Inria, LORIA, Nancy, France
 * 
 * Module description: LoopSynth algorithm [AL16] (synthesizes valuations for which there exists a loop in the PTA)
 * 
 * File contributors : Étienne André
 * Created           : 2016/08/24
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
open Statistics
open AbstractModel
open AbstractProperty
open Result
open AlgoStateBased
open State


(************************************************************)
(************************************************************)
(* Local type *)
(************************************************************)
(************************************************************)
type has_loop =
	| No_loop
	| Loop of StateSpace.scc


(************************************************************)
(************************************************************)
(* Class definition *)
(************************************************************)
(************************************************************)
class virtual algoLoopSynth (model : AbstractModel.abstract_model) (options : Options.imitator_options) =
	object (self) inherit algoStateBased model options as super
	
	(************************************************************)
	(* Class variables *)
	(************************************************************)
	
	(** Non-necessarily convex parameter constraint of the initial state (constant object used as a shortcut, as it is used at the end of the algorithm) *)
	(*** WARNING: these lines are copied from AlgoDeadlockFree ***)
	val init_p_nnconvex_constraint : LinearConstraint.p_nnconvex_constraint =
		LinearConstraint.p_nnconvex_constraint_of_p_linear_constraint model.initial_p_constraint


	(* Counters *)
	(*** NOTE: if the algorithm is called several times sequentially, then each call will create a counter ***)
	val scc_search = create_hybrid_counter_and_register "algoLoopSynth.scc_search" States_counter Verbose_experiments
	val nb_cycles = create_discrete_counter_and_register "algoLoopSynth.nb_cycles" States_counter Verbose_experiments

	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(* Name of the algorithm *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
(* 	method algorithm_name = "Cycle" *)
	
	
	
	(************************************************************)
	(* Class methods *)
	(************************************************************)

	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Variable initialization *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method! initialize_variables =
		super#initialize_variables;
		(*** NOTE: duplicate operation ***)
		synthesized_constraint <- LinearConstraint.false_p_nnconvex_constraint ();

		(* The end *)
		()
	

	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(* Add a new state to the state space (if indeed needed) *)
	(* Return true if the state is not discarded by the algorithm, i.e., if it is either added OR was already present before *)
	(* Can raise an exception TerminateAnalysis to lead to an immediate termination *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(*** TODO: return the list of actually added states ***)
	(*** WARNING/BADPROG: the following is partially copy/paste from AlgoEF.ml (though much modified) ***)
	method add_a_new_state source_state_index combined_transition new_state =

		(* Reset the mini-cache (for the p-constraint) *)
		self#reset_minicache;

		(* Try to add the new state to the state space *)
		let addition_result = state_space#add_state options#comparison_operator model.global_time_clock new_state in
		
		begin
		match addition_result with
		(* If this is really a new state, or a state larger than a former state *)
		| StateSpace.New_state new_state_index | StateSpace.State_replacing new_state_index ->

			let to_be_added =
				(*** NOTE: do NOT perform this test depending on the option ***)
			if not options#cumulative_pruning then true else(
				(* Check whether new_state.px_constraint <= synthesized_constraint *)
				if self#check_whether_px_included_into_synthesized_constraint new_state.px_constraint then(
					(* Print some information *)
					self#print_algo_message Verbose_low "Found a state included in synthesized valuations; cut branch.";

					(* Do NOT compute its successors; cut the branch *)
					false
				)else(
					true
				)
			) in
			
			(* Add the state_index to the list of new states (used to compute their successors at the next iteration) *)
			if to_be_added then(
				new_states_indexes <- new_state_index :: new_states_indexes;
			);
		 (* end if new state *)

		(* If the state was present:  *)
		| StateSpace.State_already_present new_state_index ->
			(* Not added: means this state was already present before *)
			(* This state can either be a loop or just a state belonging to another branch of a tree *)
			(* Print some information *)
			self#print_algo_message Verbose_medium ("State " ^ (StateSpace.string_of_state_index new_state_index) ^ " already met: potential cycle found.");
		end (* end if possible loop *)
		;
		
		(* Update the transitions *)
		self#add_transition_to_state_space (source_state_index, combined_transition, (*** HACK ***) match addition_result with | StateSpace.State_already_present new_state_index | StateSpace.New_state new_state_index | StateSpace.State_replacing new_state_index -> new_state_index) addition_result;
		
		let has_loop =
			match addition_result with
			(* New state: cannot be a loop *)
			| StateSpace.New_state _ -> No_loop
			(* Old state (possibly updated) -> possible loop *)
			| StateSpace.State_already_present _ | StateSpace.State_replacing _ ->
				(* Now that the transitions were updated, try to look for a loop *)
				
				(* Print some information *)
				self#print_algo_message Verbose_medium ("Computing SCC starting from s_" ^ (string_of_int source_state_index) ^ "…");

				(* Statistics *)
				scc_search#increment;
				scc_search#start;

				let scc_option = state_space#reconstruct_scc source_state_index in
				
				(* Statistics *)
				scc_search#stop;
		
				let loop_result =
				match scc_option with
					(* No loop *)
					| None ->
						(* Print some information *)
						self#print_algo_message Verbose_high "No cycle found!";
						
						No_loop
						
					(* Some loop *)
					| Some scc ->
						(* Print some information *)
						self#print_algo_message Verbose_high "Cycle found!";
						
						(* Statistics *)
						nb_cycles#increment;
						
						Loop scc
				in loop_result
		in
		
		(* If found a loop *)
		begin
		match has_loop with
			| No_loop -> ()

			| Loop scc ->
				(* Print some information *)
				self#print_algo_message Verbose_medium "Found a cycle (that may or not be accepting).";

				(*** NOTE: this method is called AFTER the transition table was updated ***)
				self#process_loop_constraint ((*** HACK ***) match addition_result with | StateSpace.State_already_present new_state_index | StateSpace.New_state new_state_index | StateSpace.State_replacing new_state_index -> new_state_index) scc new_state.px_constraint;
		end; (* end if found a loop *)
		
		(* The state is kept in any case *)
		true
	

	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** When a loop is found, update the loop constraint; current_constraint is a PX constraint that will not be modified. It will be projected onto the parameters and unified with the current parameter synthesized_constraint *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method update_loop_constraint current_constraint =
		(* Project onto the parameters *)
		let p_constraint = LinearConstraint.px_hide_nonparameters_and_collapse current_constraint in
		
		(* Projecting onto SOME parameters if required *)
		(*** BADPROG: Duplicate code (AlgoEF / AlgoPRP) ***)
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

		(* Update the loop constraint using the current constraint *)
		LinearConstraint.p_nnconvex_p_union_assign synthesized_constraint p_constraint;
		
		(* Print some information *)
		if verbose_mode_greater Verbose_medium then(
			self#print_algo_message Verbose_medium "Adding the following constraint to loop constraint:";
			print_message Verbose_medium (LinearConstraint.string_of_p_linear_constraint model.variable_names p_constraint);
			
			self#print_algo_message Verbose_medium "The loop constraint is now:";
			print_message Verbose_medium (LinearConstraint.string_of_p_nnconvex_constraint model.variable_names synthesized_constraint);
		);
		
		(* The end *)
		()



	
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Detect whether a loop is accepting *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method is_accepting _ =
		(* Here, we do not care about 'acceptance' condition: therefore, a loop is always accepting *)
		true

	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(* Actions to perform when found a loop (after updating the state space) *)
	(* Can raise an exception TerminateAnalysis to lead to an immediate termination *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method process_loop_constraint state_index scc loop_px_constraint =
		(* Process loop constraint if accepting loop *)
		if self#is_accepting scc then(
			self#print_algo_message Verbose_standard "Found an accepting cycle.";
			
			if verbose_mode_greater Verbose_low then(
				let global_location : DiscreteState.global_location = (state_space#get_state state_index).global_location in
				
				self#print_algo_message Verbose_low ("Cycling along a SCC of length " ^ (string_of_int (List.length scc)) ^ " through location: " ^ (DiscreteState.string_of_location model.automata_names model.location_names model.variable_names DiscreteState.Exact_display global_location) ^ "");
			);

			(* Just update the loop constraint *)
			self#update_loop_constraint loop_px_constraint;
			
			(* Construct counterexample if requested by the algorithm *)
			let property = Input.get_property() in
			if property.synthesis_type = Exemplification then(
				(*** temporary HACK: start from the last state of the SCC ***)
				let last_state : state_index = OCamlUtilities.list_last scc in
				
				if verbose_mode_greater Verbose_low then(
					let global_location : DiscreteState.global_location = (state_space#get_state last_state).global_location in
					
					self#print_algo_message Verbose_low ("Reconstructing the run until state `" ^ (string_of_int last_state) ^ "` of location: " ^ (DiscreteState.string_of_location model.automata_names model.location_names model.variable_names DiscreteState.Exact_display global_location) ^ "");
				);
				
				self#construct_counterexamples last_state;
			);

			(* If witness: raise TerminateAnalysis! *)
			self#terminate_if_witness;
		);
		
		(* The end *)
		()

(*	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(* Actions to perform when found a loop, after updating the state space *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method process_loop_constraint_after_state_space_update loop_starting_point_state_index loop_px_constraint =
		(* Compute the SCC (after the transitions were updated, of course) *)
		if verbose_mode_greater Verbose_low then(
			let scc = StateSpace.reconstruct_scc state_space loop_starting_point_state_index in
			(* Print it *)
			let verbose_string_of_state_index state_index =
				let state = StateSpace.get_state state_space state_index in
				"\n\ts_" ^ (string_of_int state_index) ^ "{" ^ (ModelPrinter.string_of_state model state) ^ "}"
			in
			print_message Verbose_low ("\nSCC: [" ^ (string_of_list_of_string_with_sep "\n\t- " (List.map verbose_string_of_state_index scc)) ^ "\n]");
		);
		(* The end *)
		()*)


	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Actions to perform when meeting a state with no successors: nothing to do for this algorithm *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method process_deadlock_state _ = ()
	
	
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Actions to perform at the end of the computation of the *successors* of post^n (i.e., when this method is called, the successors were just computed). Nothing to do for this algorithm. *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method process_post_n (_ : State.state_index list) = ()

	
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Check whether the algorithm should terminate at the end of some post, independently of the number of states to be processed (e.g., if the constraint is already true or false) *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(*** TODO: could be stopped when the bad constraints are equal to the initial p-constraint ***)
	method check_termination_at_post_n = false

	
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Method packaging the result output by the algorithm *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method compute_result =
		(* Print some information *)
		self#print_algo_message_newline Verbose_standard (
			"Algorithm completed " ^ (after_seconds ()) ^ "."
		);
		
		(* Retrieve the property *)
		let abstract_property = Input.get_property() in

		(* Get the termination status *)
		 let termination_status = match termination_status with
			| None -> raise (InternalError "Termination status not set in LoopSynth.compute_result")
			| Some status -> status
		in

		(* Branching between Witness/Synthesis and Exemplification *)
		if abstract_property.synthesis_type = Exemplification then(
			(* Return the result *)
			Runs_exhibition_result
			{
				(* Non-necessarily convex constraint guaranteeing the reachability of the bad location *)
				(*** NOTE: use rev since we added the runs by reversed order ***)
				runs				= List.rev_append positive_examples (List.rev negative_examples);
				
				(* Explored state space *)
				state_space			= state_space;
				
				(* Total computation time of the algorithm *)
				computation_time	= time_from start_time;
				
				(* Termination *)
				termination			= termination_status;
			}
		
		(* Normal mode: Witness/Synthesis *)
		)else(

			let soundness =
				let dangerous_inclusion = options#comparison_operator = AbstractAlgorithm.Inclusion_check || options#comparison_operator = AbstractAlgorithm.Double_inclusion_check in
				
				if dangerous_inclusion then(
					self#print_algo_message Verbose_high "A dangerous inclusion was used: result will be at least an overapproximation (or invalid)";
				);
				if options#merge_algorithm <> Merge_none then(
					self#print_algo_message Verbose_high "Merging was used: result will be at least an overapproximation (or invalid)";
				);
				
				(* EXACT if termination is normal and no inclusion nor merge *)
				if termination_status = Regular_termination && (not dangerous_inclusion) && options#merge_algorithm = Merge_none then Constraint_exact
				(* UNDER-APPROXIMATED if termination is NOT normal AND neither merging nor state inclusion was used *)
				else if termination_status <> Regular_termination && (not dangerous_inclusion) && options#merge_algorithm = Merge_none then Constraint_maybe_under
				(* OVER-APPROXIMATED if termination is normal AND merging or state inclusion was used *)
				else if termination_status = Regular_termination && (dangerous_inclusion || (options#merge_algorithm <> Merge_none)) then Constraint_maybe_over
				(* UNKNOWN otherwise *)
				else Constraint_maybe_invalid
			in

			(* Return the result *)
			Single_synthesis_result
			{
				(* Non-necessarily convex constraint guaranteeing the existence of at least one loop *)
				result				= Good_constraint (synthesized_constraint, soundness);
				
				(* English description of the constraint *)
				constraint_description = "constraint for detecting cycles";
		
				(* Explored state space *)
				state_space			= state_space;
				
				(* Total computation time of the algorithm *)
				computation_time	= time_from start_time;
				
				(* Termination *)
				termination			= termination_status;
			}
		
		)


	
(************************************************************)
(************************************************************)
end;;
(************************************************************)
(************************************************************)
