(************************************************************
 *
 *                       IMITATOR
 * 
 * Université Sorbonne Paris Nord, LIPN, CNRS, France
 *
 * Module description: Non-zenoness emptiness check using CUB transformation (synthesizes valuations for which there exists a non-zeno loop in the PTA). Distributed version.
 * 
 * File contributors : Étienne André
 * Created           : 2017/10/03
 *
 ************************************************************)


(************************************************************)
(* Modules *)
(************************************************************)
open AlgoNZCUB
open State


(************************************************************)
(* Class definition *)
(************************************************************)
class algoNZCUBdist : AbstractModel.abstract_model ->
	object inherit algoNZCUB
		(************************************************************)
		(* Class variables *)
		(************************************************************)

		method algorithm_name : string


		(************************************************************)
		(* Class methods *)
		(************************************************************)
		

end
