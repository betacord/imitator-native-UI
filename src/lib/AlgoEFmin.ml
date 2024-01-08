(************************************************************
 *
 *                       IMITATOR
 * 
 * Université Sorbonne Paris Nord, LIPN, CNRS, France
 * Université de Lorraine, CNRS, Inria, LORIA, Nancy, France
 * 
 * Module description: "EF min" algorithm: minimization of a parameter valuation for which there exists a run leading to some states [ABPP19]
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
open AlgoEFopt



(************************************************************)
(************************************************************)
(* Class definition *)
(************************************************************)
(************************************************************)
class algoEFmin (model : AbstractModel.abstract_model) (options : Options.imitator_options) (full_synthesis : bool) (state_predicate : AbstractProperty.state_predicate) (parameter_index : Automaton.parameter_index) =
	object (_) inherit algoEFopt model options full_synthesis state_predicate parameter_index
	
	(************************************************************)
	(* Class variables *)
	(************************************************************)
	
	
	(*------------------------------------------------------------*)
	(* Instantiating min/max *)
	(*------------------------------------------------------------*)
	(** Method to remove upper bounds (if minimum) or lower bounds (if maximum) *)
	method remove_bounds = LinearConstraint.p_grow_to_infinity_assign
	
	(** The closed operator (>= for minimization, and <= for maximization) *)
	method closed_op = LinearConstraint.Op_ge
	
	(** Function to negate an inequality *)
	method negate_inequality = LinearConstraint.negate_single_inequality_p_constraint
	
	
	
	(* Various strings *)
	method str_optimum = "minimum"
	method str_upper_lower = "upper"
	
	


	
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Name of the algorithm *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method algorithm_name = "EFmin"
	
	
	
	(************************************************************)
	(* Class methods *)
	(************************************************************)



	
(************************************************************)
(************************************************************)
end;;
(************************************************************)
(************************************************************)
