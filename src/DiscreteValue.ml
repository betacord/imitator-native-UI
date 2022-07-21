(************************************************************
 *
 *                       IMITATOR
 *
 * Laboratoire Spécification et Vérification (ENS Cachan & CNRS, France)
 * Université Paris 13, LIPN, CNRS, France
 * Université de Lorraine, CNRS, Inria, LORIA, Nancy, France
 *
 * Module description: Contain all types and functions for operations onto discrete value
 *
 * File contributors : Benjamin L., Étienne André
 * Created           : 2021/03/01
 *
 ************************************************************)

open Constants
open Exceptions
open DiscreteType

(* Discrete value of different specific types *)
(*
type discrete_number_value =
    | Weak_number_value of NumConst.t
    | Rational_value2 of NumConst.t
    | Int_value2 of Int32.t

type discrete_scalar_value =
    | Number_value of discrete_number_value
    | Bool_value2 of bool
    | Binary_word_value2 of BinaryWord.t

type xxx =
    | Scalar_value of discrete_scalar_value
    | Array_value2 of discrete_scalar_value array
    | List_value2 of discrete_scalar_value list
    | Stack_value2 of discrete_scalar_value Stack.t
    | Queue_value2 of discrete_scalar_value Queue.t
*)

type discrete_value =
    | Number_value of NumConst.t
    | Rational_value of NumConst.t
    | Int_value of Int32.t
    | Bool_value of bool
    | Binary_word_value of BinaryWord.t
    | Array_value of discrete_value array
    | List_value of discrete_value list
    | Stack_value of discrete_value Stack.t
    | Queue_value of discrete_value Queue.t

(*
type rational_t
type number_t
type fake_array
type fake_list
type fake_stack
type fake_queue
type 'a array_t = 'a array
type 'a list_t = 'a list
type 'a stack_t = 'a * fake_stack
type 'a queue_t = 'a * fake_queue

type _ discrete_value2 =
    | Number_value : NumConst.t -> number_t discrete_value2
    | Rational_value : NumConst.t -> rational_t discrete_value2
    | Int_value : Int32.t -> Int32.t discrete_value2
    | Bool_value : Bool.t -> Bool.t discrete_value2
    | Binary_word_value : BinaryWord.t -> BinaryWord.t discrete_value2
    | Array_value : ('a discrete_value2) array -> ('a array_t) discrete_value2
    | List_value : 'a discrete_value2 list -> 'a list_t discrete_value2
    | Stack_value : 'a discrete_value2 Stack.t -> 'a stack_t discrete_value2
    | Queue_value : 'a discrete_value2 Queue.t -> 'a queue_t discrete_value2

let add (type t) (a : t discrete_value2) (b : t discrete_value2) : t discrete_value2 =
  match a, b with
  | Number_value a, Number_value b -> Number_value (NumConst.add a b)
  | Rational_value a, Rational_value b -> Rational_value (NumConst.add a b)
  | Int_value a, Int_value b -> Int_value (Int32.add a b)
*)

(* Get discrete var type of a discrete value *)
let rec discrete_type_of_value = function
    | Number_value _ -> Var_type_discrete_number Var_type_discrete_unknown_number
    | Rational_value _ -> Var_type_discrete_number Var_type_discrete_rat
    | Int_value _ -> Var_type_discrete_number Var_type_discrete_int
    | Bool_value _ -> Var_type_discrete_bool
    | Binary_word_value value -> Var_type_discrete_binary_word (BinaryWord.length value)
    | Array_value a ->
        if Array.length a = 0 then
            Var_type_discrete_array (Var_type_weak, 0)
        else
            Var_type_discrete_array (discrete_type_of_value (Array.get a 0), Array.length a)
    | List_value l ->
        if List.length l = 0 then
            Var_type_discrete_list Var_type_weak
        else
            Var_type_discrete_list (discrete_type_of_value (List.nth l 0))
    | Stack_value l ->
        if Stack.length l = 0 then
            Var_type_discrete_stack Var_type_weak
        else
            Var_type_discrete_stack (discrete_type_of_value (Stack.top l))
    | Queue_value l ->
        if Queue.length l = 0 then
            Var_type_discrete_queue Var_type_weak
        else
            Var_type_discrete_queue (discrete_type_of_value (Queue.peek l))

(* Get var type of a discrete value *)
let var_type_of_value value =
    Var_type_discrete (discrete_type_of_value value)

(* Check if a value is compatible with given type *)
let check_value_compatible_with_type value var_type =
    (* Get discrete type of value *)
    let value_type = discrete_type_of_value value in
    (* Get discrete type of var type *)
    let var_type_discrete = discrete_type_of_var_type var_type in
    (* Check compatibility of discrete types *)
    is_discrete_type_compatibles var_type_discrete value_type

(************************************************************)
(** Value functions  *)
(************************************************************)

(** String of values  **)
let rec customized_string_of_value customized_string = function
    | Number_value x
    | Rational_value x -> NumConst.string_of_numconst x
    | Bool_value x -> if x then customized_string.boolean_string.true_string else customized_string.boolean_string.false_string
    | Int_value x -> Int32.to_string x
    | Binary_word_value b -> BinaryWord.string_of_binaryword b
    | Array_value a ->
        let str_values = Array.map (fun x -> customized_string_of_value customized_string x) a in
        let l_delimiter, r_delimiter = customized_string.array_string.array_literal_delimiter in
        l_delimiter ^ OCamlUtilities.string_of_array_of_string_with_sep ", " str_values ^ r_delimiter
    | List_value l ->
        let str_values = List.map (fun x -> customized_string_of_value customized_string x) l in
        let l_delimiter, r_delimiter = customized_string.array_string.array_literal_delimiter in
        (* TODO benjamin remove hardcoded "list([a,b,c])" *)
        "list(" ^ l_delimiter ^ OCamlUtilities.string_of_list_of_string_with_sep ", " str_values ^ r_delimiter ^ ")"
    | Stack_value s ->
        let str_values_with_extra_comma = Stack.fold (fun acc x -> acc ^ customized_string_of_value customized_string x ^ ", ") "" s in
        let str_values = if Stack.length s > 0 then String.sub str_values_with_extra_comma 0 ((String.length str_values_with_extra_comma) - 2) else str_values_with_extra_comma in
        let l_delimiter, r_delimiter = customized_string.array_string.array_literal_delimiter in
        (* TODO benjamin CLEAN remove hardcoded "stack([a,b,c])" *)
        if str_values = "" then "stack()" else "stack(" ^ l_delimiter ^ str_values ^ r_delimiter ^ ")"

    | Queue_value q ->
        let str_values_with_extra_comma = Queue.fold (fun acc x -> acc ^ customized_string_of_value customized_string x ^ ", ") "" q in
        let str_values = if Queue.length q > 0 then String.sub str_values_with_extra_comma 0 ((String.length str_values_with_extra_comma) - 2) else str_values_with_extra_comma in
        let l_delimiter, r_delimiter = customized_string.array_string.array_literal_delimiter in
        (* TODO benjamin CLEAN remove hardcoded "queue([a,b,c])" *)
        if str_values = "" then "queue()" else "queue(" ^ l_delimiter ^ str_values ^ r_delimiter ^ ")"

let string_of_value = customized_string_of_value global_default_string

(** Check value type  **)

(* Check whether the value is rational *)
let is_rational_value = function
    | Rational_value _ -> true
    | _ -> false

(* Check whether the value is int *)
let is_int_value = function
    | Int_value _ -> true
    | _ -> false

(* Check whether the value is boolean *)
let is_bool_value = function
    | Bool_value _ -> true
    | _ -> false

(* Check whether the value is binary word *)
let is_binary_word_value = function
    | Binary_word_value _ -> true
    | _ -> false

(* Constructor functions *)

(* Get discrete value from NumConst.t *)
let of_numconst x = Rational_value x
(* Get discrete value from Int32.t *)
let of_int x = Int_value x
(* Get discrete value from bool *)
let of_bool x = Bool_value x

(** Default values  **)

(* Default discrete rational value *)
let default_rational = Rational_value NumConst.zero
(* Default discrete int value *)
let default_int = Int_value Int32.zero
(* Default discrete bool value *)
let default_bool = Bool_value false
(* Default discrete binary word value *)
let default_binary_word_value l = Binary_word_value (BinaryWord.zero l)
(* Default discrete list value *)
let default_list_value = List_value []
(* Default discrete stack value *)
let default_stack_value = Stack_value (Stack.create ())
(* Default discrete stack value *)
let default_queue_value = Queue_value (Queue.create ())


(* Get default discrete number value *)
let default_discrete_number_value = function
    | Var_type_discrete_unknown_number
    | Var_type_discrete_rat -> default_rational
    | Var_type_discrete_int -> default_int

(* Get default discrete value *)
let rec default_discrete_value = function
    | Var_type_weak -> raise (InternalError "Unable to have default value of a weak typed variable.")
    | Var_type_discrete_number x -> default_discrete_number_value x
    | Var_type_discrete_bool -> default_bool
    | Var_type_discrete_binary_word l -> default_binary_word_value l
    | Var_type_discrete_array (inner_type, length) -> Array_value (Array.make length (default_discrete_value inner_type))
    | Var_type_discrete_list inner_type -> default_list_value
    | Var_type_discrete_stack inner_type -> default_stack_value
    | Var_type_discrete_queue inner_type -> default_queue_value

(* Get default discrete value *)
let default_value = function
    | Var_type_clock -> default_rational
    | Var_type_parameter -> default_rational
    | Var_type_discrete var_type_discrete -> default_discrete_value var_type_discrete

(* Get zero value of Rational_value *)
let rational_zero = default_rational
(* Get false value of Bool_value *)
let bool_value_false = default_bool
(* Get true value of Bool_value *)
let bool_value_true = Bool_value true

let is_zero = function
    | Number_value value
    | Rational_value value -> value = NumConst.zero
    | Int_value value -> value = Int32.zero
    | value -> false

(** Convert values  **)

(* Get NumConst.t value of rational discrete value *)
let numconst_value = function
    | Rational_value x -> x
    | v -> raise (InternalError ("Unable to get rational value of non-rational discrete value: " ^ string_of_value v))

(* Get Int32.t value of int32 discrete value *)
let int_value = function
    | Int_value x -> x
    | v -> raise (InternalError ("Unable to get int value of non-int discrete value: " ^ string_of_value v ^ ":" ^ string_of_var_type (var_type_of_value v)))

(* Get bool value of bool discrete value *)
let bool_value = function
    | Bool_value x -> x
    | v -> raise (InternalError ("Unable to get bool value of non-bool discrete value" ^ string_of_value v))

(* Get array value of discrete value *)
let array_value = function
    | Array_value x -> x
    | v -> raise (InternalError ("Unable to get array value of non-array discrete value: " ^ string_of_value v))

(* Get list value of discrete value *)
let list_value = function
    | List_value x -> x
    | v -> raise (InternalError ("Unable to get list value of non-list discrete value: " ^ string_of_value v))

(* Get stack value of discrete value *)
let stack_value = function
    | Stack_value x -> x
    | v -> raise (InternalError ("Unable to get stack value of non-stack discrete value: " ^ string_of_value v))

(* Get queue value of discrete value *)
let queue_value = function
    | Queue_value x -> x
    | v -> raise (InternalError ("Unable to get stack value of non-queue discrete value: " ^ string_of_value v))


(* Convert any discrete value to NumConst.t value, if possible *)
let to_numconst_value = function
    | Number_value x
    | Rational_value x -> x
    (* Warning, a bit is lost when converting on 32 bit platform !*)
    | Int_value x -> NumConst.numconst_of_int (Int32.to_int x)
    | value -> raise (InternalError ("Unable to convert " ^ string_of_value value ^ " to rational NumConst.t value"))

let convert_to_numconst = function
    | Number_value x
    | Rational_value x -> x
    | Int_value x -> NumConst.numconst_of_int (Int32.to_int x)
    | Bool_value x -> if x then NumConst.one else NumConst.zero
    | Binary_word_value x -> NumConst.numconst_of_int (BinaryWord.to_int x)
    | _ -> NumConst.zero (* Cannot convert list, array to numconst ! *)


(* Convert any discrete value to Int32 value, if possible *)
let to_int_value = function
    (* Warning !!!! conversion to int should be dependant of the platform ! *)
    | Number_value x
    | Rational_value x -> Int32.of_int (NumConst.to_int x)
    | Bool_value x -> if x then Int32.one else Int32.zero
    (* Warning, a bit is lost when converting on 32 bit platform !*)
    | Int_value x -> x
    | Binary_word_value x -> Int32.of_int (BinaryWord.hash x)
    | Array_value _ -> raise (InternalError "Unable to convert array to Int32.t value")
    | List_value _ -> raise (InternalError "Unable to convert list to Int32.t value")
    | Stack_value _ -> raise (InternalError "Unable to convert stack to Int32.t value")
    | Queue_value _ -> raise (InternalError "Unable to convert queue to Int32.t value")

(* Convert any discrete value to float value, if possible *)
let to_float_value = function
    | Number_value x
    | Rational_value x -> (NumConst.to_float x)
    | Bool_value x -> if x then 1.0 else 0.0
    | Int_value x -> Int32.to_float x
    | Binary_word_value x -> float_of_int (BinaryWord.hash x)
    | Array_value _ -> raise (InternalError "Unable to convert array to float value")
    | List_value _ -> raise (InternalError "Unable to convert list to float value")
    | Stack_value _ -> raise (InternalError "Unable to convert stack to float value")
    | Queue_value _ -> raise (InternalError "Unable to convert queue to float value")


(* Get binary word value of discrete value *)
let binary_word_value = function
    | Binary_word_value x -> x
    | _ as value -> raise (InternalError ("Unable to get binary word value of non binary word `" ^ string_of_value value ^ "`"))




(* Convert any discrete value to a Rational_value *)
let convert_to_rational_value value =
    Rational_value (to_numconst_value value)

(* Hash code of discrete value *)
let rec hash = function
    | Number_value x
    | Rational_value x -> Gmp.Z.to_int (NumConst.get_num x)
    | Bool_value x -> if x then 1 else 0
    | Int_value x -> Int32.to_int x
    | Binary_word_value b -> BinaryWord.hash b
    (* Arbitrary *)
    | Array_value a -> Array.fold_left (fun acc x -> acc + (hash x)) 0 a
    | List_value l -> List.fold_left (fun acc x -> acc + (hash x)) 0 l
    | Stack_value s -> Stack.fold (fun acc x -> acc + (hash x)) 0 s
    | Queue_value s -> Queue.fold (fun acc x -> acc + (hash x)) 0 s

(** Dynamic computing operations on values  **)

(* Check if a discrete value is equal to another discrete value *)
let equal a b =
    match a, b with
    | Number_value a, Number_value b
    | Rational_value a, Rational_value b -> NumConst.equal a b
    | Bool_value a, Bool_value b -> a = b
    | Int_value a, Int_value b -> Int32.equal a b
    | Binary_word_value a, Binary_word_value b -> BinaryWord.equal a b
    | Array_value a, Array_value b -> a = b
    | List_value a, List_value b -> a = b
    | Stack_value a, Stack_value b -> a = b
    | Queue_value a, Queue_value b -> a = b
    | lt, rt -> raise (
        InternalError ("Computing exception on `"
            ^ string_of_var_type_discrete (discrete_type_of_value lt)
            ^ " = "
            ^ string_of_var_type_discrete (discrete_type_of_value rt)
            ^ "`"
        )
    )

(* Check if a discrete value is not equal to another discrete value *)
let neq a b =
    not (equal a b)
