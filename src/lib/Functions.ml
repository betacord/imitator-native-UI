(************************************************************
 *
 *                       IMITATOR
 *
 * Université de Lorraine, CNRS, Inria, LORIA, Nancy, France
 *
 * Module description: This module enable definition of customs IMITATOR functions
 * In order to define a new IMITATOR function, just add it's signature and tag to know if it is subject to side effects
 *
 * File contributors : Benjamin L.
 * Created           : 2021/11/20
 *
 ************************************************************)

(* Utils modules *)
open OCamlUtilities

(* Parsing structure modules *)
open ParsingStructure

(* Abstract model modules *)
open DiscreteExpressions
open FunctionSig



(* Shortcuts to hash table types *)
(* type functions_meta_table = (string, function_metadata) Hashtbl.t *)
(* type parsed_functions_table = (string, parsed_fun_definition) Hashtbl.t *)


(* binary(l) -> l -> binary(l) *)
let shift_signature =
    [
        Defined_type_constraint (Binary_constraint (Length_constraint_expression (Length_scalar_constraint "a")));
        Defined_type_constraint (Number_constraint (Defined_type_number_constraint (Int_constraint Int_type_constraint)));
        Defined_type_constraint (Binary_constraint (Length_constraint_expression (Length_scalar_constraint "a")))
    ]

(* binary(l) -> l':int -> binary(l + l') *)
let fill_signature =
    [
        Defined_type_constraint (Binary_constraint (Length_constraint_expression (Length_scalar_constraint "l1")));
        Defined_type_constraint (Number_constraint (Defined_type_number_constraint (Int_constraint (Int_name_constraint "l"))));
        Defined_type_constraint (Binary_constraint (Length_constraint_expression (Length_plus_constraint ("l", Length_constraint_expression (Length_scalar_constraint "l1")))))
    ]

(* binary(l) -> binary(l) *)
let unary_log_signature =
    [
        Defined_type_constraint (Binary_constraint (Length_constraint_expression (Length_scalar_constraint "a")));
        Defined_type_constraint (Binary_constraint (Length_constraint_expression (Length_scalar_constraint "a")))
    ]

(* binary(l) -> binary(l) -> binary(l) *)
let binary_log_signature =
    [
        Defined_type_constraint (Binary_constraint (Length_constraint_expression (Length_scalar_constraint "a")));
        Defined_type_constraint (Binary_constraint (Length_constraint_expression (Length_scalar_constraint "a")));
        Defined_type_constraint (Binary_constraint (Length_constraint_expression (Length_scalar_constraint "a")))
    ]

(* Extract metadata from abstract model function definition *)
let metadata_of_function_definition (fun_def : AbstractModel.fun_definition) : ParsingStructure.function_metadata =
    {
        name = fun_def.name;
        parameter_refs = fun_def.parameter_refs;
        signature_constraint = fun_def.signature_constraint;
        side_effect = fun_def.side_effect;
    }

(* Get a variable ref for parameter of given name *)
let variable_ref_of_name name = (name, -1)
let variable_refs_of_names = List.map variable_ref_of_name

(* Get builtin function implementations *)
let builtin_function_bodies : AbstractModel.fun_definition list =
    [
        {
            name = "pow";
            parameter_refs = variable_refs_of_names ["x"; "exp"];
            signature_constraint = [
                Defined_type_constraint (Number_constraint (Number_type_name_constraint "a"));
                Defined_type_constraint (Number_constraint (Defined_type_number_constraint (Int_constraint Int_type_constraint)));
                Defined_type_constraint (Number_constraint (Number_type_name_constraint "a"))
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_pow;
            side_effect = false;
        };
        {
            name = "mod";
            parameter_refs = variable_refs_of_names ["a"; "b"];
            signature_constraint = [
                Defined_type_constraint (Number_constraint (Defined_type_number_constraint (Int_constraint Int_type_constraint)));
                Defined_type_constraint (Number_constraint (Defined_type_number_constraint (Int_constraint Int_type_constraint)));
                Defined_type_constraint (Number_constraint (Defined_type_number_constraint (Int_constraint Int_type_constraint)));
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_mod;
            side_effect = false;
        };
        {
            name = "int_div";
            parameter_refs = variable_refs_of_names ["a"; "b"];
            signature_constraint = [
                Defined_type_constraint (Number_constraint (Defined_type_number_constraint (Int_constraint Int_type_constraint)));
                Defined_type_constraint (Number_constraint (Defined_type_number_constraint (Int_constraint Int_type_constraint)));
                Defined_type_constraint (Number_constraint (Defined_type_number_constraint (Int_constraint Int_type_constraint)));
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_int_div;
            side_effect = false;
        };
        {
            name = "rational_of_int";
            parameter_refs = variable_refs_of_names ["r"];
            signature_constraint = [
                Defined_type_constraint (Number_constraint (Defined_type_number_constraint (Int_constraint Int_type_constraint)));
                Defined_type_constraint (Number_constraint (Defined_type_number_constraint Rat_constraint))
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_rational_of_int;
            side_effect = false
        };
        {
            name = "shift_left";
            parameter_refs = variable_refs_of_names ["b"; "i"];
            signature_constraint = shift_signature;
            body = Fun_builtin DiscreteExpressionEvaluator.eval_shift_left;
            side_effect = false
        };
        {
            name = "shift_right";
            parameter_refs = variable_refs_of_names ["b"; "i"];
            signature_constraint = shift_signature;
            body = Fun_builtin DiscreteExpressionEvaluator.eval_shift_right;
            side_effect = false
        };
        {
            name = "fill_left";
            parameter_refs = variable_refs_of_names ["b"; "i"];
            signature_constraint = fill_signature;
            body = Fun_builtin DiscreteExpressionEvaluator.eval_fill_left;
            side_effect = false
        };
        {
            name = "fill_right";
            parameter_refs = variable_refs_of_names ["b"; "i"];
            signature_constraint = fill_signature;
            body = Fun_builtin DiscreteExpressionEvaluator.eval_fill_right;
            side_effect = false
        };
        {
            name = "logand";
            parameter_refs = variable_refs_of_names ["b1"; "b2"];
            signature_constraint = binary_log_signature;
            body = Fun_builtin DiscreteExpressionEvaluator.eval_log_and;
            side_effect = false
        };
        {
            name = "logor";
            parameter_refs = variable_refs_of_names ["b1"; "b2"];
            signature_constraint = binary_log_signature;
            body = Fun_builtin DiscreteExpressionEvaluator.eval_log_or;
            side_effect = false
        };
        {
            name = "logxor";
            parameter_refs = variable_refs_of_names ["b1"; "b2"];
            signature_constraint = binary_log_signature;
            body = Fun_builtin DiscreteExpressionEvaluator.eval_log_xor;
            side_effect = false
        };
        {
            name = "lognot";
            parameter_refs = variable_refs_of_names ["b1"];
            signature_constraint = unary_log_signature;
            body = Fun_builtin DiscreteExpressionEvaluator.eval_log_not;
            side_effect = false
        };
        {
            name = "array_copy";
            parameter_refs = variable_refs_of_names ["a"];
            signature_constraint = [
                Defined_type_constraint (Array_constraint (Type_name_constraint "a", Length_constraint_expression (Length_scalar_constraint "l")));
                Defined_type_constraint (Array_constraint (Type_name_constraint "a", Length_constraint_expression (Length_scalar_constraint "l")));
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_array_copy;
            side_effect = false
        };
        {
            name = "array_append";
            parameter_refs = variable_refs_of_names ["a1"; "a2"];
            signature_constraint = [
                Defined_type_constraint (Array_constraint (Type_name_constraint "a", Length_constraint_expression (Length_scalar_constraint "l1")));
                Defined_type_constraint (Array_constraint (Type_name_constraint "a", Length_constraint_expression (Length_scalar_constraint "l2")));
                Defined_type_constraint (Array_constraint (Type_name_constraint "a", Length_constraint_expression (Length_plus_constraint ("l1", Length_constraint_expression (Length_scalar_constraint "l2")))));
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_array_append;
            side_effect = false
        };
        {
            name = "array_mem";
            parameter_refs = variable_refs_of_names ["a"; "e"];
            signature_constraint = [
                Type_name_constraint "a";
                Defined_type_constraint (Array_constraint (Type_name_constraint "a", Length_constraint_expression (Length_scalar_constraint "l")));
                Defined_type_constraint Bool_constraint
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_array_mem;
            side_effect = false
        };
        {
            name = "array_length";
            parameter_refs = variable_refs_of_names ["a"];
            signature_constraint = [
                Defined_type_constraint (Array_constraint (Type_name_constraint "a", Length_constraint_expression (Length_scalar_constraint "l")));
                Defined_type_constraint (Number_constraint (Defined_type_number_constraint (Int_constraint Int_type_constraint)))
           ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_array_length;
            side_effect = false
        };
        {
            name = "list_is_empty";
            parameter_refs = variable_refs_of_names ["l"];
            signature_constraint = [
                Defined_type_constraint (List_constraint (Type_name_constraint "a"));
                Defined_type_constraint Bool_constraint
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_list_is_empty;
            side_effect = false
        };
        {
            name = "list_cons";
            parameter_refs = variable_refs_of_names ["l"; "e"];
            signature_constraint = [
                Type_name_constraint "a";
                Defined_type_constraint (List_constraint (Type_name_constraint "a"));
                Defined_type_constraint (List_constraint (Type_name_constraint "a"))
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_list_cons;
            side_effect = false
        };
        {
            name = "list_hd";
            parameter_refs = variable_refs_of_names ["l"];
            signature_constraint = [
                Defined_type_constraint (List_constraint (Type_name_constraint "a"));
                Type_name_constraint "a";
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_list_hd;
            side_effect = false
        };
        {
            name = "list_tl";
            parameter_refs = variable_refs_of_names ["l"];
            signature_constraint = [
                Defined_type_constraint (List_constraint (Type_name_constraint "a"));
                Defined_type_constraint (List_constraint (Type_name_constraint "a"));
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_list_tl;
            side_effect = false
        };
        {
            name = "list_rev";
            parameter_refs = variable_refs_of_names ["l"];
            signature_constraint = [
                Defined_type_constraint (List_constraint (Type_name_constraint "a"));
                Defined_type_constraint (List_constraint (Type_name_constraint "a"));
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_list_rev;
            side_effect = false
        };
        {
            name = "list_mem";
            parameter_refs = variable_refs_of_names ["e"; "l"];
            signature_constraint = [
                Type_name_constraint "a";
                Defined_type_constraint (List_constraint (Type_name_constraint "a"));
                Defined_type_constraint Bool_constraint
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_list_mem;
            side_effect = false
        };
        {
            name = "list_length";
            parameter_refs = variable_refs_of_names ["l"];
            signature_constraint = [
                Defined_type_constraint (List_constraint (Type_name_constraint "a"));
                Defined_type_constraint (Number_constraint (Defined_type_number_constraint (Int_constraint Int_type_constraint)))
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_list_length;
            side_effect = false
        };
        {
            name = "stack_copy";
            parameter_refs = variable_refs_of_names ["s"];
            signature_constraint = [
                Defined_type_constraint (Stack_constraint (Type_name_constraint "a"));
                Defined_type_constraint (Stack_constraint (Type_name_constraint "a"));
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_stack_copy;
            side_effect = false
        };
        {
            name = "stack_push";
            parameter_refs = variable_refs_of_names ["s"; "e"];
            signature_constraint = [
                Type_name_constraint "a";
                Defined_type_constraint (Stack_constraint (Type_name_constraint "a"));
                Defined_type_constraint Void_constraint
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_stack_push;
            side_effect = true
        };
        {
            name = "stack_pop";
            parameter_refs = variable_refs_of_names ["s"];
            signature_constraint = [
                Defined_type_constraint (Stack_constraint (Type_name_constraint "a"));
                Type_name_constraint "a"
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_stack_pop;
            side_effect = true
        };
        {
            name = "stack_top";
            parameter_refs = variable_refs_of_names ["s"];
            signature_constraint = [
                Defined_type_constraint (Stack_constraint (Type_name_constraint "a"));
                Type_name_constraint "a"
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_stack_top;
            side_effect = false
        };
        {
            name = "stack_clear";
            parameter_refs = variable_refs_of_names ["s"];
            signature_constraint = [
                Defined_type_constraint (Stack_constraint (Type_name_constraint "a"));
                Defined_type_constraint Void_constraint
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_stack_clear;
            side_effect = true
        };
        {
            name = "stack_is_empty";
            parameter_refs = variable_refs_of_names ["s"];
            signature_constraint = [
                Defined_type_constraint (Stack_constraint (Type_name_constraint "a"));
                Defined_type_constraint Bool_constraint
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_stack_is_empty;
            side_effect = false
        };
        {
            name = "stack_length";
            parameter_refs = variable_refs_of_names ["s"];
            signature_constraint = [
                Defined_type_constraint (Stack_constraint (Type_name_constraint "a"));
                Defined_type_constraint (Number_constraint (Defined_type_number_constraint (Int_constraint Int_type_constraint)))
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_stack_length;
            side_effect = false
        };
        {
            name = "queue_copy";
            parameter_refs = variable_refs_of_names ["s"];
            signature_constraint = [
                Defined_type_constraint (Queue_constraint (Type_name_constraint "a"));
                Defined_type_constraint (Queue_constraint (Type_name_constraint "a"));
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_stack_copy;
            side_effect = false
        };
        {
            name = "queue_push";
            parameter_refs = variable_refs_of_names ["e"; "q"];
            signature_constraint = [
                Type_name_constraint "a";
                Defined_type_constraint (Queue_constraint (Type_name_constraint "a"));
                Defined_type_constraint Void_constraint
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_stack_push;
            side_effect = true
        };
        {
            name = "queue_pop";
            parameter_refs = variable_refs_of_names ["q"];
            signature_constraint = [
                Defined_type_constraint (Queue_constraint (Type_name_constraint "a"));
                Type_name_constraint "a"
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_stack_pop;
            side_effect = true
        };
        {
            name = "queue_top";
            parameter_refs = variable_refs_of_names ["q"];
            signature_constraint = [
                Defined_type_constraint (Queue_constraint (Type_name_constraint "a"));
                Type_name_constraint "a"
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_stack_top;
            side_effect = false
        };
        {
            name = "queue_clear";
            parameter_refs = variable_refs_of_names ["q"];
            signature_constraint = [
                Defined_type_constraint (Queue_constraint (Type_name_constraint "a"));
                Defined_type_constraint Void_constraint
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_stack_clear;
            side_effect = true
        };
        {
            name = "queue_is_empty";
            parameter_refs = variable_refs_of_names ["q"];
            signature_constraint = [
                Defined_type_constraint (Queue_constraint (Type_name_constraint "a"));
                Defined_type_constraint Bool_constraint
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_stack_is_empty;
            side_effect = false
        };
        {
            name = "queue_length";
            parameter_refs = variable_refs_of_names ["q"];
            signature_constraint = [
                Defined_type_constraint (Queue_constraint (Type_name_constraint "a"));
                Defined_type_constraint (Number_constraint (Defined_type_number_constraint (Int_constraint Int_type_constraint)))
            ];
            body = Fun_builtin DiscreteExpressionEvaluator.eval_stack_length;
            side_effect = false
        };
        {
            name = "fake";
            parameter_refs = variable_refs_of_names ["e"];
            signature_constraint = [
                Defined_type_constraint (List_constraint (Defined_type_constraint (List_constraint (Type_name_constraint "a"))));
                Defined_type_constraint (List_constraint (Defined_type_constraint (List_constraint (Type_name_constraint "a"))));
            ];
            body = Fun_builtin (fun _ -> raise (Exceptions.InternalError "implement function"));
            side_effect = false
        };
    ]

(* List of builtin functions metadata *)
let builtin_functions_metadata : ParsingStructure.function_metadata list =
    List.map metadata_of_function_definition builtin_function_bodies

(* Get builtin function metadata as a table *)
let builtin_functions_metadata_table =
    builtin_functions_metadata
    |> List.map (fun (fun_def : function_metadata) -> fun_def.name, fun_def)
    |> OCamlUtilities.hashtbl_of_tuples

(* Get builtin function implementations as a table *)
let builtin_function_bodies_table =
    builtin_function_bodies
    |> List.map (fun (fun_def : AbstractModel.fun_definition) -> fun_def.name, fun_def)
    |> OCamlUtilities.hashtbl_of_tuples

(* Compute metadata of a user defined function definition *)
let metadata_of_parsed_function_definition builtin_functions_metadata_table user_function_definitions_table (fun_def : parsed_fun_definition) =
    (* Concat parameters type and return type *)
    let signature = List.map second_of_tuple fun_def.parameters @ [fun_def.return_type] in
    {
        name = fun_def.name;
        parameter_refs = List.map first_of_tuple fun_def.parameters;
        signature_constraint = FunctionSig.signature_constraint_of_signature signature;
        side_effect = ParsingStructureMeta.is_function_has_side_effects builtin_functions_metadata_table user_function_definitions_table fun_def;
    }

(* Get arity of a function given it's name *)
let arity_of_function variable_infos function_name =
    let function_metadata = VariableInfo.function_metadata_by_name variable_infos function_name in
    (List.length (function_metadata.signature_constraint)) - 1