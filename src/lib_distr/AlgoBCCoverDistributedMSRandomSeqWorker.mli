(************************************************************
 *
 *                       IMITATOR
 * 
 * Université Sorbonne Paris Nord, LIPN, CNRS, France
 * Université de Lorraine, CNRS, Inria, LORIA, Nancy, France
 * 
 * Module description: Classical Behavioral Cartography with exhaustive coverage of integer points [AF10]. Distribution mode: master-worker with random pi0 and n retries before switching to sequential mode. [ACE14]
 * Worker algorithm
 * 
 * File contributors : Étienne André
 * Created           : 2016/03/16
 *
 ************************************************************)


	
(************************************************************)
(* Modules *)
(************************************************************)


(************************************************************)
(* Class definition *)
(************************************************************)
class algoBCCoverDistributedMSRandomSeqWorker : AbstractModel.abstract_model -> AbstractProperty.abstract_property -> HyperRectangle.hyper_rectangle -> NumConst.t -> (PVal.pval -> AlgoStateBased.algoStateBased) -> AlgoCartoGeneric.tiles_storage ->
	object inherit AlgoBCCoverDistributedMSPointBasedWorker.algoBCCoverDistributedMSPointBasedWorker

		(************************************************************)
		(* Class variables *)
		(************************************************************)


		(************************************************************)
		(* Class methods *)
		(************************************************************)
		method algorithm_name : string

end