(************************************************************
 *
 *                       IMITATOR
 * 
 * Université Sorbonne Paris Nord, LIPN, CNRS, France
 * 
 * Module description: "EF" algorithm (unsafe w.r.t. a set of bad states) [JLR15]
 * 
 * File contributors : Étienne André
 * Created           : 2023/12/18
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
open AlgoEUgen



(************************************************************)
(************************************************************)
(* Class definition *)
(************************************************************)
(************************************************************)
class algoEF (model : AbstractModel.abstract_model) (property : AbstractProperty.abstract_property) (options : Options.imitator_options) (state_predicate : AbstractProperty.state_predicate) =
	object (self) inherit algoEUgen model property options None state_predicate (*as super*)

	(************************************************************)
	(* Class variables *)
	(************************************************************)
	
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Name of the algorithm *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method algorithm_name = "EF"
	
	(************************************************************)
	(* Class methods *)
	(************************************************************)

	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Method packaging the result output by the algorithm *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method compute_result =
		(* Print some information *)
		self#print_algo_message_newline Verbose_standard (
			"Algorithm completed " ^ (after_seconds ()) ^ "."
		);


		(*** TODO: compute as well *good* zones, depending whether the analysis was exact, or early termination occurred ***)

		(* Projecting onto SOME parameters if required *)
		(*** NOTE: Useless test as we are in EF, so there is a property ***)
		let result =
			match property.projection with
				(* No projection: copy the initial p constraint *)
				| None -> synthesized_constraint
				(* Project *)
				| Some parameters ->
					(* Print some information *)
					if verbose_mode_greater Verbose_medium then(
						self#print_algo_message Verbose_medium "Projecting the bad constraint onto some of the parameters.";
						self#print_algo_message Verbose_medium "Before projection:";
						print_message Verbose_medium (LinearConstraint.string_of_p_nnconvex_constraint model.variable_names synthesized_constraint);
					);

					(*** TODO! do only once for all… ***)
					let all_but_projectparameters = list_diff model.parameters parameters in

					(* Eliminate other parameters *)
					let projected_synthesized_constraint = LinearConstraint.p_nnconvex_hide all_but_projectparameters synthesized_constraint in

					(* Print some information *)
					if verbose_mode_greater Verbose_medium then(
						self#print_algo_message Verbose_medium "After projection:";
						print_message Verbose_medium (LinearConstraint.string_of_p_nnconvex_constraint model.variable_names projected_synthesized_constraint);
					);

					(* Return *)
					projected_synthesized_constraint
		in

		(* Get the termination status *)
		 let termination_status = match termination_status with
			| None -> raise (InternalError ("Termination status not set in " ^ (self#algorithm_name) ^ ".compute_result"))
			| Some status -> status
		in

		(* Branching between Witness/Synthesis and Exemplification *)
		if property.synthesis_type = Exemplification then(
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

			(* Constraint is exact if termination is normal, possibly under-approximated otherwise *)
			(*** NOTE/TODO: technically, if the constraint is true/false, its soundness can be further refined easily ***)
			let soundness = if termination_status = Regular_termination then Constraint_exact else Constraint_maybe_under in

			(* Return the result *)
			Single_synthesis_result
			{
				(* Non-necessarily convex constraint guaranteeing the reachability of the desired states *)
				result				= Good_constraint (result, soundness);

				(* English description of the constraint *)
				constraint_description = "constraint guaranteeing reachability";

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
