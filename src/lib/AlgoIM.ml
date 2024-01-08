(************************************************************
 *
 *                       IMITATOR
 * 
 * Université Sorbonne Paris Nord, LIPN, CNRS, France
 * Université de Lorraine, CNRS, Inria, LORIA, Nancy, France
 * 
 * Module description: IM algorithm [ACEF09]
 * 
 * File contributors : Étienne André
 * Created           : 2016/01/06
 *
 ************************************************************)


(************************************************************)
(************************************************************)
(* Modules *)
(************************************************************)
(************************************************************)
open ImitatorUtilities
open Exceptions
open Result
open AlgoIMK
open State



(************************************************************)
(************************************************************)
(* Class definition *)
(************************************************************)
(************************************************************)
class algoIM (model : AbstractModel.abstract_model) (abstract_property : AbstractProperty.abstract_property) (options : Options.imitator_options) (pval : PVal.pval) =
	object (self) inherit algoIMK model abstract_property options pval (*as super*)
	
	(************************************************************)
	(* Class variables *)
	(************************************************************)
	
	
	
	(************************************************************)
	(* Class methods *)
	(************************************************************)

	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Name of the algorithm *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method! algorithm_name = "IMconvex"

	
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Method packaging the result output by the algorithm *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method! compute_result =
		(*** NOTE: Method used here: intersection of all p-constraints ***)
		(* Alternative methods would have been: 1) on-the-fly intersection (everytime a state is met) or 2) intersection of all final states, i.e., member of a loop, or deadlock states *)

		(* Create the result *)
		let p_constraint = LinearConstraint.p_true_constraint() in
		
		self#print_algo_message Verbose_low ("Performing the intersection of all p-constraints…");
		
		(* Iterate on all states *)
		state_space#iterate_on_states (fun _ abstract_state ->
			(* Retrieve the px-constraint *)
			let px_linear_constraint = abstract_state.px_constraint in
			(* Project onto the parameters *)
			let projection = LinearConstraint.px_hide_nonparameters_and_collapse px_linear_constraint in
			(* Intersect with the result *)

			(*** TODO: check if only one intersection with the list of all projections gathered would be more efficient ??? ***)
			
			LinearConstraint.p_intersection_assign p_constraint [projection];
		);
		
	
		self#print_algo_message_newline Verbose_standard (
			"Successfully terminated " ^ (after_seconds ()) ^ "."
		);

		(* Get the termination status *)
		 let termination_status = match termination_status with
			| None -> raise (InternalError "Termination status not set in IM.compute_result")
			| Some status -> status
		in

		(* Constraint is… *)
		let soundness = 
			let dangerous_inclusion = options#comparison_operator = AbstractAlgorithm.Inclusion_check || options#comparison_operator = AbstractAlgorithm.Including_check || options#comparison_operator = AbstractAlgorithm.Double_inclusion_check in

			(* EXACT if termination is normal and no random selections and no incl and no merge were performed *)
			if termination_status = Regular_termination && nb_random_selections = 0 && not dangerous_inclusion && (options#merge_algorithm = Merge_none) then Constraint_exact
			(* UNDER-APPROXIMATED if termination is normal and random selections and no incl and no merge were performed *)
			else if termination_status = Regular_termination && nb_random_selections > 0 && not dangerous_inclusion && (options#merge_algorithm = Merge_none) then Constraint_maybe_under
			(* OVER-APPROXIMATED if no random selections were performed and either termination is not normal or merging was used or state inclusion was used *)
			else if nb_random_selections = 0 && (termination_status <> Regular_termination || dangerous_inclusion || (options#merge_algorithm <> Merge_none)) then Constraint_maybe_over
			(* UNKNOWN otherwise *)
			else Constraint_maybe_invalid
		in
		
		let result = Good_constraint(LinearConstraint.p_nnconvex_constraint_of_p_linear_constraint p_constraint, soundness) in

		(* Return result *)
		Point_based_result
		{
			(* Reference valuation *)
			reference_val		= self#get_reference_pval;
			
			(* Result of the algorithm *)
			result				= result;
			
			(* Explored state space *)
			state_space			= state_space;
			
			(* Number of random selections of pi-incompatible inequalities performed *)
(* 			nb_random_selections= nb_random_selections; *)
	
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
