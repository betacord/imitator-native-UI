(************************************************************
 *
 *                       IMITATOR
 * 
 * Université Sorbonne Paris Nord, LIPN, CNRS, France
 * Université de Lorraine, CNRS, Inria, LORIA, Nancy, France
 * 
 * Module description: Random Behavioral Cartography with a maximum number of consecutive failed attempts to find a non-integer point not covered by any tile, then followed by a sequential check point by point. Described in the distributed setting in [ACE14,ACN15]
 * Note: the algorithm does NOT track points already computed randomly but not kept because covered by some tile.
 * 
 * File contributors : Étienne André
 * Created           : 2016/03/16
 *
 ************************************************************)


(************************************************************)
(************************************************************)
(* Modules *)
(************************************************************)
(************************************************************)
open ImitatorUtilities
open Exceptions
open AlgoCartoGeneric


(************************************************************)
(************************************************************)
(* Local type *)
(************************************************************)
(************************************************************)

type phase =
	(* Phase 1: random phase *)
	| Random_phase

	(* Phase 2: sequential phase *)
	| Sequential_phase


(************************************************************)
(************************************************************)
(* Class definition *)
(************************************************************)
(************************************************************)

class algoBCRandomSeq (model : AbstractModel.abstract_model) (property : AbstractProperty.abstract_property) (options : Options.imitator_options) (v0 : HyperRectangle.hyper_rectangle) (step : NumConst.t) (max_tries: int) (algo_instance_function : (PVal.pval -> AlgoStateBased.algoStateBased)) (tiles_manager_type : tiles_storage) =
	object (self) inherit algoCartoGeneric model property options v0 step algo_instance_function tiles_manager_type (*as super*)
	
	(************************************************************)
	(* Class variables *)
	(************************************************************)
	(* Current number of failed attempts to find an integer point not covered by any tile *)
(* 	val mutable nb_failed_attempts = 0 *)

	val mutable phase : phase = Random_phase
	
	
	(************************************************************)
	(* Class methods *)
	(************************************************************)

	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Name of the algorithm *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method algorithm_name = "BC (random(" ^ (string_of_int max_tries) ^ ") + sequential)"


	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Create the initial point for the analysis *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method get_initial_point =
		(* Return a random point *)
		Some_pval (self#one_random_pi0)

	
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Find the next point *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method find_next_point =
		match phase with
		(* Case 1: random phase *)
		| Random_phase -> (
			(* Print some information *)
			self#print_algo_message Verbose_low ("Trying to randomly find a fresh pi0 with " ^ (string_of_int max_tries) ^ " tries.");

			(* Call random function *)
			let result = self#try_random_pi0 max_tries in

			match result with
			(* Some point: fine! *)
			| Some_pval pval -> Some_pval pval
			
			(* Cannot find points randomly: switch! *)
			| No_more -> (
				(* Switch phase *)
				phase <- Sequential_phase;
				
				(* Print some information *)
				self#print_algo_message Verbose_standard ("Now switching to sequential algorithm");
				
				(* Compute the initial point *)
				let smallest_point =  self#compute_smallest_point in
				
				(* If it is not covered, return it *)
				if self#test_pi0_uncovered smallest_point then
					Some_pval smallest_point
				
				else
				(* Otherwise find the next uncovered point *)
				self#compute_next_sequential_uncovered_pi0_from smallest_point
			)
		)
		(* Case 2: sequential phase *)
		| Sequential_phase ->
			(* Directly call dedicated function *)
			self#compute_next_sequential_uncovered_pi0



	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	(** Method packaging the result output by the algorithm *)
	(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
	method compute_bc_result =
		self#print_algo_message_newline Verbose_standard (
			"Successfully terminated " ^ (after_seconds ()) ^ "."
		);

		
		(* Get the termination status *)
		 let termination_status = match termination_status with
			| None -> raise (InternalError "Termination status not set in BCRandomSeq.compute_bc_result")
			| Some status -> status
		in
		
		(* Retrieve the manager *)
		let tiles_manager = self#get_tiles_manager in
		
		(* Ask the tiles manager to process the result itself, by passing the appropriate arguments *)
		tiles_manager#process_result start_time v0 nb_points nb_unsuccessful_points termination_status None


(************************************************************)
(************************************************************)
end;;
(************************************************************)
(************************************************************)
