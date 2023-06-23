(************************************************************
 *
 *                       IMITATOR
 * 
 * Université Paris 13, LIPN, CNRS, France
 * Université de Lorraine, CNRS, Inria, LORIA, Nancy, France
 * 
 * Module description: "EF max" algorithm: maximization of a parameter valuation for which there exists a run leading to some states [ABPP19]
 * 
 * File contributors : Étienne André
 * Created           : 2017/05/02
 *
 ************************************************************)


(************************************************************)
(************************************************************)
(* Modules *)
(************************************************************)
(************************************************************)
open ImitatorUtilities
open AbstractModel
open AlgoEFopt
open LinearConstraint


(************************************************************)
(************************************************************)
(* Class definition *)
(************************************************************)
(************************************************************)
class algoEFmax (model : AbstractModel.abstract_model) (options : Options.imitator_options) (state_predicate : AbstractProperty.state_predicate) (parameter_index : Automaton.parameter_index) =
	object (self) inherit algoEFopt model options state_predicate parameter_index
	
	(************************************************************)
	(* Class variables *)
	(************************************************************)
	
	
	(*------------------------------------------------------------*)
	(* Instantiating min/max *)
	(*------------------------------------------------------------*)
	(** Method to remove upper bounds (if minimum) or lower bounds (if maximum) *)
	method remove_bounds = LinearConstraint.p_grow_to_zero_assign
	
	(** The closed operator (>= for minimization, and <= for maximization) *)
	method closed_op = LinearConstraint.Op_le


	(*** NOTE: we kind of need to 'reimplement' the negate_single_inequality_p_constraint function, because there may be some p >= 0 inequality, that we do not need to negate ***)
	method negate_inequality p_linear_constraint =
		
		(* Print some information *)
		if verbose_mode_greater Verbose_medium then(
			self#print_algo_message Verbose_medium "Negating constraint:";
			self#print_algo_message Verbose_medium (LinearConstraint.string_of_p_linear_constraint model.variable_names p_linear_constraint);
		);
		
		let result = negate_single_inequality_nonnegative_p_constraint parameter_index p_linear_constraint in
		
		(* Print some information *)
		if verbose_mode_greater Verbose_medium then(
			self#print_algo_message Verbose_medium "Result:";
			self#print_algo_message Verbose_medium (LinearConstraint.string_of_p_linear_constraint model.variable_names result);
		);
		
		result


	
	(* Various strings *)
	method str_optimum = "maximum"
	method str_upper_lower = "lower"

	
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Name of the algorithm *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method algorithm_name = "EFmax"
	
	
	
	(************************************************************)
	(* Class methods *)
	(************************************************************)



	
(************************************************************)
(************************************************************)
end;;
(************************************************************)
(************************************************************)
