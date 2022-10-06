(************************************************************
 *
 *                       IMITATOR
 *
 * Université de Lorraine, CNRS, Inria, LORIA, Nancy, France
 * Université Sorbonne Paris Nord, LIPN, CNRS, France
 *
 * Module description: validity synthesis, i.e., return the set of valuations for which the initial state is defined
 *
 * File contributors : Étienne André
 * Created           : 2022/10/07
 *
 ************************************************************)


(************************************************************)
(* Modules *)
(************************************************************)
open AlgoStateBased
open State


(************************************************************)
(* Class definition *)
(************************************************************)
class algoValid :
	object inherit algoStateBased
		(************************************************************)
		(* Class variables *)
		(************************************************************)

		method algorithm_name : string

		(************************************************************)
		(* Class methods *)
		(************************************************************)
		
		method initialize_variables : unit
		
		(*------------------------------------------------------------*)
		(* Add a new state to the state space (if indeed needed) *)
		(* Return true if the state is not discarded by the algorithm, i.e., if it is either added OR was already present before *)
		(* Can raise an exception TerminateAnalysis to lead to an immediate termination *)
		(*------------------------------------------------------------*)
		(*** TODO: return the list of actually added states ***)
		method add_a_new_state : state_index -> StateSpace.combined_transition -> State.state -> bool

		
		(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
		(** Actions to perform with the initial state; returns true unless the initial state cannot be kept (in which case the algorithm will stop immediately) *)
		(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
		method process_initial_state : State.state -> bool
		

		(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
		(* Actions to perform when meeting a state with no successors: nothing to do for this algorithm *)
		(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
		method process_deadlock_state : state_index -> unit
		
		
		(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
		(** Actions to perform at the end of the computation of the *successors* of post^n (i.e., when this method is called, the successors were just computed). Nothing to do for this algorithm. *)
		(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
		method process_post_n : state_index list -> unit

		
		(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
		(** Check whether the algorithm should terminate at the end of some post, independently of the number of states to be processed (e.g., if the constraint is already true or false) *)
		(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
		method check_termination_at_post_n : bool

		
		method compute_result : Result.imitator_result
end
