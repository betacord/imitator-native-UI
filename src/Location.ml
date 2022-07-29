(************************************************************
 *
 *                       IMITATOR
 * 
 * Laboratoire Spécification et Vérification (ENS Cachan & CNRS, France)
 * Université Paris 13, LIPN, CNRS, France
 * Université de Lorraine, CNRS, Inria, LORIA, Nancy, France
 * 
 * Module description: define global locations
 * 
 * File contributors        : Étienne André
 * Created                  : 2010/03/10
 * Renamed from Automaton.ml: 2015/10/22
 * Last modified            : 2020/09/28
 *
 ************************************************************)
 

(************************************************************)
(* Modules *)
(************************************************************)
open OCamlUtilities
open Automaton
open AbstractProperty



(************************************************************)
(** {2 Types} *)
(************************************************************)

(** Unique identifier for each different global location *)
type global_location_index = int

(* Array automaton_index -> location_index *)
type locations = location_index array

(* Array discrete_index -> discrete_value *)
type discrete = AbstractValue.abstract_value array

(* Global location: location for each automaton + value of the discrete *)
type global_location = locations * discrete


exception NotEqual

let location_equal loc1 loc2 =
	let (locs1, discr1) = loc1 in
	let (locs2, discr2) = loc2 in
	(* can use polymorphic = here *)
	if not (locs1 = locs2) then false else (
		if not ((Array.length discr1) = (Array.length discr2)) then false else (
			try (
				Array.iteri (fun i d1 -> 
					if not (discr2.(i) = d1) then raise NotEqual
				) discr1;
				true
			) with _ -> false
			(* all entries equal *)			
		) 
	)


(** Should the float be displaid using exact rationals or (possibly approximated) floats? *)
type rational_display =
	| Exact_display
	| Float_display


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
(** {3 Automata} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)

type automaton_index = int
type automaton_name = string




(************************************************************)
(** Global variables *)
(************************************************************)

(* The minimum discrete_index *)
let min_discrete_index = ref 0

(* The number of discrete variables *)
let nb_discrete = ref 0

(* The number of automata *)
let nb_automata = ref 0

(************************************************************)
(** Useful functions *)
(************************************************************)

let get_locations (locations, _) =	locations

let get_discrete (_, discrete) = discrete

(*let location_hash_code location =
	let locations = get_locations location in
	Array.fold_left (fun h loc -> 
		7919 * h + loc
	) 0 locations*)

let hash_code location =
	let locations, discrete = location in
	let loc_hash = Array.fold_left (fun h loc -> 2*h + loc) 0 locations in
	let discr_hash = Array.fold_left (fun h q -> 
		2*h + (AbstractValue.hash q)
	) 0 discrete in
	loc_hash + 3 * discr_hash

(* Replace a discrete variable by its name, considering the offset *)
let string_of_discrete names index =
	names (index + !min_discrete_index)


(************************************************************)
(** {2 Locations} *)
(************************************************************)

(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
(** {3 Initialization} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)

(** 'initialize nb_automata min_discrete_index max_discrete_index' initializes the min and max discrete indexes and the number of automata. *)
let initialize nb_auto min_discrete max_discrete =
	min_discrete_index := min_discrete;
	nb_discrete := max_discrete - min_discrete + 1;
	nb_automata := nb_auto


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
(** {3 Creation} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
(** 'make_location locations discrete_values' creates a new location. All automata should be given a location. Discrete variables may not be given a value (in which case they will be initialized to 0). *)
let make_location locations_per_automaton discrete_values =
	(* Create an array for locations *)
	let locations = Array.make !nb_automata 0 in
	(* Create an array for discrete *)
	let discrete = Array.make !nb_discrete AbstractValue.rational_zero in
	(* Iterate on locations *)
	List.iter (fun (automaton_index, location_index) -> locations.(automaton_index) <- location_index) locations_per_automaton;
	(* Iterate on discrete *)
	List.iter (fun (discrete_index, value) -> discrete.(discrete_index - !min_discrete_index) <- value) discrete_values;
	(* Return the new location *)
	locations, discrete

(* We have to copy discrete values of arrays and stacks *)
(* Because of array and stack are references in OCaml, if we don't copy their content *)
(* discrete values stay the same between previous location and new location leading to a misbehavior. *)
(* This is due to the fact that the update in-place of their values or their content will update old and new location *)
(* as it was the same references. *)
(* As it was possible to update content of array in IMITATOR via a[i] = x, or stack by stack_push(x, s) *)
(* List isn't concerned because we doesn't have ability to modify it's content in IMITATOR. *)
let copy_discrete_at_location location =
	(* Get discrete variables *)
	let discretes = get_discrete location in
	(* Copy discrete variables *)
	let cpy_discretes = Array.map AbstractValue.deep_copy discretes in
	(* Copy array of discrete variables *)
	cpy_discretes

(** 'copy_location location' creates a fresh location identical to location. *)
let copy_location location =
	(* Create an array for locations *)
	let locations = Array.copy (get_locations location) in
	(* Create an array for discrete *)
	let discrete = copy_discrete_at_location location in
	(* Return the new location *)
	locations, discrete

(*
(** 'update_location locations discrete_values location' creates a new location from the original location, and update the given automata and discrete variables. *)
let update_location locations_per_automaton discrete_values location =
	(* Create an array for locations *)
	let locations = Array.copy (get_locations location) in
	(* Create an array for discrete *)
	let discrete = Array.copy (get_discrete location) in
	(* Iterate on locations *)
	List.iter (fun (automaton_index, location_index) -> locations.(automaton_index) <- location_index) locations_per_automaton;
	(* Iterate on discrete *)
	List.iter (fun (discrete_index, value) -> discrete.(discrete_index - !min_discrete_index) <- value) discrete_values;
	(* Return the new location *)
	locations, discrete
*)

(* Side-effect function for updating a discrete variable given a value at given location *)
let update_discrete_with (discrete_index, value) (_, discrete) =
    discrete.(discrete_index - !min_discrete_index) <- value

(** Side-effect version of 'update_location'. *)
let update_location_with locations_per_automaton discrete_values (locations, discrete) =
	(* Iterate on locations *)
	List.iter (fun (automaton_index, location_index) -> locations.(automaton_index) <- location_index) locations_per_automaton;
	(* Iterate on discrete *)
	List.iter (fun (discrete_index, value) -> discrete.(discrete_index - !min_discrete_index) <- value) discrete_values




(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
(** {3 Access} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)

(** Get the location associated to some automaton *)
let get_location location automaton_index =
	let locations = get_locations location in
	locations.(automaton_index)

(** Get the value associated to some discrete variable *)
let get_discrete_value location discrete_index =
	let discrete = get_discrete location in
	(* Do not forget the offset *)
	discrete.(discrete_index - !min_discrete_index)

(** Get the NumConst value associated to some discrete variable *)
let get_discrete_rational_value location discrete_index =
    let value = get_discrete_value location discrete_index in
    AbstractValue.numconst_value value

(** Set the value associated to some discrete variable *)
let set_discrete_value location discrete_index value =
    let discrete = get_discrete location in
	(* Do not forget the offset *)
    discrete.(discrete_index - !min_discrete_index) <- value

(** Get a tuple of functions for reading / writing a global variable at a given location *)
(* A discrete access enable to read or write a value of a variable at a given discrete index *)
let discrete_access_of_location location =
    get_discrete_value location, set_discrete_value location


(************************************************************)
(* Check whether the global location is accepting *)
(************************************************************)

(** Check whether a global location is accepting according to the accepting condition of the model of the form `automaton_index -> location_index -> acceptance of location_index in automaton_index` *)
let is_accepting (locations_acceptance_condition : automaton_index -> location_index -> bool) (global_location : global_location) =
	(* Check whether a local location is accepting *)
	get_locations global_location |> Array.mapi locations_acceptance_condition |> Array.exists identity

(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)
(** {3 Conversion} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*)

(** 'string_of_location automata_names location_names discrete_names location' converts a location to a string. *)
let string_of_location automata_names location_names discrete_names rational_display location =
	(* Get the locations per automaton *)
	let locations = get_locations location in
	(* Get the values for discrete variables *)
	let discrete = get_discrete location in
	(* Convert the locations *)
	let string_array = Array.mapi (fun automaton_index location_index ->
		(automata_names automaton_index) ^ ": " ^ (location_names automaton_index location_index)
	) locations in
	let location_string = string_of_array_of_string_with_sep ", " string_array in
	(* Convert the discrete *)
	let string_array = Array.mapi (fun discrete_index value ->
		(string_of_discrete discrete_names discrete_index) ^ " = " ^ (AbstractValue.string_of_value value) ^ (
			(* Convert to float? *)
			match rational_display with
			| Exact_display -> ""
			| Float_display -> " (~ " ^ (string_of_float (AbstractValue.to_float_value value)) ^ ")"
		)
	) discrete in
	let discrete_string = string_of_array_of_string_with_sep ", " string_array in
	(* Return the string *)
	location_string ^ (if !nb_discrete > 0 then ", " else "") ^ discrete_string
	

	
