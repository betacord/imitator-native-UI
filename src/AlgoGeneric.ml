(************************************************************
 *
 *                       IMITATOR
 * 
 * Université Paris 13, LIPN, CNRS, France
 * 
 * Module description: root of the class hierarchy of algorithms. Only most basic functions are defined.
 * 
 * File contributors : Étienne André
 * Created           : 2016/01/19
 *
 ************************************************************)


(**************************************************************)
(* Modules *)
(**************************************************************)
open ImitatorUtilities


(**************************************************************)
(* Class definition *)
(**************************************************************)
class virtual algoGeneric (model : AbstractModel.abstract_model) =
	object (self)

	(************************************************************)
	(* Class variables *)
	(************************************************************)
	(* Start time for the algorithm *)
	val mutable start_time = 0.

	(*------------------------------------------------------------*)
	(* Shortcuts *)
	(*------------------------------------------------------------*)
	
	(* Retrieve the model *)
	val model = Input.get_model ()
	
	(* Retrieve the input options *)
	val options = Input.get_options ()
	
	
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(* Virtual method: the algorithm name is to be defined in concrete classes *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method virtual algorithm_name : string
	

	(************************************************************)
	(* Class methods *)
	(************************************************************)
	
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(* Write a message preceeded by "[algorithm_name]" *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method print_algo_message verbose_mode message =
		print_message verbose_mode ("  [" ^ self#algorithm_name ^ "] " ^ message)
	
	
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(* Write an error message preceeded by "[algorithm_name]" *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method print_algo_error message =
		print_error ("  [" ^ self#algorithm_name ^ "] " ^ message)
	
	
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(* Write a message preceeded by "\n[algorithm_name]" *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method print_algo_message_newline verbose_mode message =
		print_message verbose_mode ("\n  [" ^ self#algorithm_name ^ "] " ^ message)
	
	
	(* Variable initialization (to be defined in subclasses) *)
	method virtual initialize_variables : unit
	
	(* Main method to run the algorithm: virtual method to be defined in subclasses *)
	method virtual run : unit -> Result.imitator_result
	

(************************************************************)
(************************************************************)
end;;
(************************************************************)
(************************************************************)
