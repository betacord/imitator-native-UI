(************************************************************
 *
 *                       IMITATOR
 *
 * Module description: utilities for deadlock checking
 *
 * File contributors : Mikael Bisgaard Dahlsen-Jensen, Jaco van de Pol
 * Created           : 2022
 *
 ************************************************************)


 (* JvdP: add some auxiliary code for deadlock checking, Paris July 2022 *)

open LinearConstraint
open DiscreteExpressionEvaluator
open State

let dl_instantiate_discrete_gen discrete constr = 
    pxd_intersection_assign discrete [constr];
    pxd_hide_discrete_and_collapse discrete

(** go from pxd-constraint to px-constraint by substituting concrete values for discrete variables *)
let dl_instantiate_discrete (model : AbstractModel.abstract_model) (state_space : StateSpace.stateSpace) state_index constr =
	let glob_location = state_space#get_location (state_space#get_global_location_index state_index) in
    let discrete = State.discrete_constraint_of_global_location model glob_location in
    dl_instantiate_discrete_gen discrete constr

(*(** go from pxd-constraint to px-constraint by substituting concrete values for discrete variables *)
let dl_instantiate_discrete_after_seq (state_space : StateSpace.stateSpace) state_index constr transition =
	let glob_location = state_space#get_location (state_space#get_global_location_index state_index) in

    (* Copy location where we perform the destructive sequential updates*)
    let location = DiscreteState.copy_location glob_location in
    let model = Input.get_model() in 

    (* Create a fresh copy of the local variables table *)
    let local_variables_table : DiscreteState.local_variables_table = Hashtbl.copy model.local_variables_table in

	let global_location_and_local_variables : DiscreteState.global_location_and_local_variables = DiscreteState.make_global_location_and_local_variables location local_variables_table in

    (* Get functions that enable reading / writing global variables at a given location *)
    let discrete_access = DiscreteState.discrete_access_of_location_and_local_variables global_location_and_local_variables in
    (* Make all sequential update first ! *)
	List.iter (fun transition_index ->
		(* Get the automaton concerned *)
		(* Access the transition and get the components *)
		let transitions_description = model.transitions_description transition_index in

        let _, update_seq_code_bloc = transitions_description.updates in
        eval_seq_code_bloc (Some model.variable_names) (Some model.functions_table) discrete_access update_seq_code_bloc;
	) transition;

    let discrete = State.discrete_constraint_of_global_location model location in

    dl_instantiate_discrete_gen discrete constr*)

(* go from pxd-constraint to px-constraint by substituting concrete values for discrete variables *)
let dl_discrete_constraint_of_global_location (model : AbstractModel.abstract_model) (state_space : StateSpace.stateSpace) state_index transition =
	let glob_location = state_space#get_location (state_space#get_global_location_index state_index) in

    (* Copy location where we perform the destructive sequential updates*)
    let location = DiscreteState.copy_location glob_location in

    (* Create a fresh copy of the local variables table *)
    let local_variables_table : DiscreteState.local_variables_table = Hashtbl.copy model.local_variables_table in

	let global_location_and_local_variables : DiscreteState.global_location_and_local_variables = DiscreteState.make_global_location_and_local_variables location local_variables_table in

    (* Get functions that enable reading / writing global variables at a given location *)
    let discrete_access = DiscreteState.discrete_access_of_location_and_local_variables global_location_and_local_variables in

    (* Create context *)
    let eval_context = DiscreteExpressionEvaluator.create_eval_context discrete_access in

    (* Make all sequential update first ! *)
	List.iter (fun transition_index ->
		(* Get the automaton concerned *)
		(* Access the transition and get the components *)
		let transitions_description = model.transitions_description transition_index in

        let _, update_seq_code_bloc = transitions_description.updates in
        eval_seq_code_bloc_with_context (Some model.variable_names) (Some model.functions_table) eval_context update_seq_code_bloc;
	) transition;

    State.discrete_constraint_of_global_location model location,
    DiscreteExpressionEvaluator.effective_clock_updates eval_context model.variable_names

(*(* "undo" the effect of updates on zone z (by computing the weakest precondition) *)
(* This is probably incomplete, if there was also a discrete update *) 
let dl_inverse_update (state_space : StateSpace.stateSpace) state_index z updates transition =
    let model = Input.get_model () in
    let constr = px_copy z in
    let constr_pxd = pxd_of_px_constraint constr in
    (State.apply_updates_assign_backward model constr_pxd updates);

    let constr_px = dl_instantiate_discrete_after_seq state_space state_index constr_pxd transition in



    constr_px*)

(* "undo" the effect of updates on zone z (by computing the weakest precondition) *)
(* This is probably incomplete, if there was also a discrete update *)
let dl_inverse_update_ben_fix (model : AbstractModel.abstract_model) (state_space : StateSpace.stateSpace) state_index z transition =
    let constr = px_copy z in
    let constr_pxd = pxd_of_px_constraint constr in

    let discrete_constr, effective_clock_updates = dl_discrete_constraint_of_global_location model state_space state_index transition in
    State.apply_updates_assign_backward model constr_pxd [effective_clock_updates];
    dl_instantiate_discrete_gen discrete_constr constr_pxd




(** Apply past time operator *)
let dl_inverse_time (model : AbstractModel.abstract_model) (state_space : StateSpace.stateSpace) state_index z =
	let glob_location = state_space#get_location (state_space#get_global_location_index state_index) in
    AlgoStateBased.apply_time_past model glob_location z


(* compute direct predecessor of z2 in z1, linked by (guard,updates) *)
let dl_predecessor (model : AbstractModel.abstract_model) state_space state_index z1 guard z2 transition =
    let constr = dl_inverse_update_ben_fix model state_space state_index z2 transition in
    px_intersection_assign constr [z1];
    let constr_pxd = pxd_of_px_constraint constr in
    pxd_intersection_assign constr_pxd [guard];
    
    constr_pxd
    (* result *)

(* this extends get_resets: we return (x,0) for resets and (x,lt) for updates *)
(* TODO CLEAN, unused now we are using effective clock updates to know which clocks are updated EFFECTIVELY *)
(*
let dl_get_clock_updates (state_space : StateSpace.stateSpace) combined_transition =
	(* Retrieve the model *)
	let model = Input.get_model () in

	(* For all transitions involved in the combined transition *)
	let updates = List.fold_left (fun current_updates transition_index ->
		(* Get the actual transition *)
		let transition = model.transitions_description transition_index in
		let clock_updates, _ = transition.updates in
        clock_updates :: current_updates
	) [] combined_transition
	in

	(* Keep each update once *)
    (* TODO: check for inconsistent updates? see with new sequential updates and rewritten clocks ! *)
	OCamlUtilities.list_only_once updates
*)

let dl_weakest_precondition (model : AbstractModel.abstract_model) (state_space : StateSpace.stateSpace) s1_index transition s2_index =
    let z1 = (state_space#get_state s1_index).px_constraint in
    let z2 = (state_space#get_state s2_index).px_constraint in
  
    let guard = state_space#get_guard model s1_index transition in
 
    dl_predecessor model state_space s1_index z1 guard z2 transition
