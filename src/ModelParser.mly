/************************************************************
 *
 *                       IMITATOR
 *
 * Laboratoire Spécification et Vérification (ENS Cachan & CNRS, France)
 * Université Paris 13, LIPN, CNRS, France
 * Université de Lorraine, CNRS, Inria, LORIA, Nancy, France
 *
 * Module description: Parser for the input model
 *
 * File contributors : Étienne André, Jaime Arias, Benjamin Loillier, Laure Petrucci
 * Created           : 2009/09/07
 *
 ************************************************************/


%{
open ParsingStructure;;
open Exceptions;;
open NumConst;;
open ImitatorUtilities;;
open DiscreteType;;


let parse_error s =
	let symbol_start = symbol_start () in
	let symbol_end = symbol_end () in
	raise (ParsingError (symbol_start, symbol_end))
;;


(*** TODO (Jaime): is it included twice ? ***)
let include_list = ref [];;

let add_parsed_model_to_parsed_model_list parsed_model_list parsed_model =
	{
		controllable_actions	= List.append parsed_model.controllable_actions parsed_model_list.controllable_actions;
		variable_declarations	= List.append parsed_model.variable_declarations parsed_model_list.variable_declarations;
    fun_definitions = List.append parsed_model.fun_definitions parsed_model_list.fun_definitions;
		automata				= List.append parsed_model.automata parsed_model_list.automata;
		init_definition			= List.append parsed_model.init_definition parsed_model_list.init_definition;
	}
;;

let unzip l = List.fold_left
	add_parsed_model_to_parsed_model_list
	{
		controllable_actions	= [];
		variable_declarations	= [];
    fun_definitions = [];
		automata				= [];
		init_definition			= [];
	}
	(List.rev l)
;;

%}

%token <NumConst.t> INT
%token <string> FLOAT
%token <string> BINARYWORD
%token <string> NAME
/* %token <string> STRING */
%token <ParsingStructure.parsed_model> INCLUDE

%token OP_PLUS OP_MINUS OP_MUL OP_DIV
%token OP_L OP_LEQ OP_EQ OP_NEQ OP_GEQ OP_G OP_ASSIGN

%token LPAREN RPAREN LBRACE RBRACE LSQBRA RSQBRA
%token AMPERSAND APOSTROPHE COLON COMMA DOUBLEDOT PIPE SEMICOLON

%token
	CT_ACCEPTING CT_ACTIONS CT_AND CT_AUTOMATON
	CT_CLOCK CT_CONSTANT CT_CONTINUOUS CT_CONTROLLABLE
	CT_VOID CT_DISCRETE CT_INT CT_BOOL CT_BINARY_WORD CT_ARRAY
	CT_INSIDE
	CT_DO
	CT_IN
	CT_ELSE CT_END
	CT_FALSE CT_FLOW
	CT_GOTO
	CT_IF CT_INIT CT_INVARIANT CT_IS
	CT_LOC
	CT_NOT
	CT_OR
	CT_PARAMETER
	CT_STOP CT_SYNC CT_SYNCLABS
	CT_THEN CT_TRUE
	CT_URGENT
	CT_VAR
	CT_WAIT CT_WHEN CT_WHILE
	/*** NOTE: just to forbid their use in the input model and property ***/
	CT_NOSYNCOBS CT_OBSERVER CT_OBSERVER_CLOCK CT_SPECIAL_RESET_CLOCK_NAME
    CT_BUILTIN_FUNC_RATIONAL_OF_INT /* CT_POW CT_SHIFT_LEFT CT_SHIFT_RIGHT CT_FILL_LEFT CT_FILL_RIGHT
    CT_LOG_AND CT_LOG_OR CT_LOG_XOR CT_LOG_NOT CT_ARRAY_CONCAT CT_LIST_CONS */ CT_LIST CT_STACK CT_QUEUE
    CT_FUN CT_RETURN CT_BEGIN CT_FOR CT_FROM CT_TO CT_DOWNTO CT_DONE


%token EOF

%right OP_ASSIGN
%right OP_EQ

%left PIPE CT_OR        /* lowest precedence */
%left AMPERSAND CT_AND  /* medium precedence */
%left DOUBLEDOT         /* high precedence */
%nonassoc CT_NOT        /* highest precedence */

%left OP_PLUS OP_MINUS  /* lowest precedence */
%left OP_MUL OP_DIV     /* highest precedence */


%start main             /* the entry point */
%type <ParsingStructure.parsed_model> main
%%

/************************************************************/
main:
	controllable_actions_option variables_declarations decl_fun_lists automata init_definition_option
	end_opt EOF
	{
		let controllable_actions	= $1 in
		let declarations			= $2 in
		let fun_definitions 		= $3 in
		let automata				= $4 in
		let init_definition			= $5 in

		let main_model =
		{
			controllable_actions	= controllable_actions;
			variable_declarations	= declarations;
			fun_definitions			= fun_definitions;
			automata				= automata;
			init_definition			= init_definition;
		}
		in

		let included_model = unzip !include_list in

		(* Return the parsed model *)
		add_parsed_model_to_parsed_model_list included_model main_model
	}
;

end_opt:
	| CT_END { }
	| { }
;




/************************************************************
  CONTROLLABLE ACTIONS
************************************************************/
controllable_actions_option:
	| CT_CONTROLLABLE CT_ACTIONS COLON name_list SEMICOLON { $4 }
	| { [] }
;


/************************************************************
  VARIABLE DECLARATIONS
************************************************************/

/************************************************************/

variables_declarations:
	| include_file_list CT_VAR decl_var_lists { $3 }
	| { []}
;


/************************************************************
	INCLUDES
************************************************************/
include_file_list:
	| include_file include_file_list  { $1 :: $2 }
	| { [] }
;

include_file:
	| INCLUDE SEMICOLON { $1 }
;


/************************************************************/

/************************************************************/

decl_var_lists:
	| decl_var_list COLON var_type SEMICOLON decl_var_lists { (($3, $1) :: $5) }
	| { [] }
;

/************************************************************/

decl_var_list:
	| NAME comma_opt { [($1, None)] }
	| NAME OP_EQ boolean_expression comma_opt { [($1, Some $3)] }

	| NAME COMMA decl_var_list { ($1, None) :: $3 }
	| NAME OP_EQ boolean_expression COMMA decl_var_list { ($1, Some $3) :: $5 }
;

/************************************************************/

var_type:
	| CT_CLOCK { Var_type_clock }
	| CT_CONSTANT { Var_type_discrete (Dt_number Dt_rat) }
	| CT_PARAMETER { Var_type_parameter }
	| var_type_discrete { Var_type_discrete $1 }
;

var_type_discrete:
    | var_type_discrete_number { Dt_number $1 }
    | CT_VOID { Dt_void }
    | CT_BOOL { Dt_bool }
    | CT_BINARY_WORD LPAREN pos_integer RPAREN { Dt_bin (NumConst.to_bounded_int $3) }
    | var_type_discrete_array { $1 }
    | var_type_discrete_list { $1 }
    | var_type_discrete_stack { $1 }
    | var_type_discrete_queue { $1 }
;

var_type_discrete_array:
  | var_type_discrete CT_ARRAY LPAREN pos_integer RPAREN { Dt_array ($1, NumConst.to_bounded_int $4) }
;

var_type_discrete_list:
  | var_type_discrete CT_LIST { Dt_list $1 }
;

var_type_discrete_stack:
  | var_type_discrete CT_STACK { Dt_stack $1 }
;

var_type_discrete_queue:
  | var_type_discrete CT_QUEUE { Dt_queue $1 }
;

var_type_discrete_number:
    | CT_DISCRETE { Dt_rat }
    | CT_INT { Dt_int }
;

/************************************************************/

decl_fun_lists:
	| decl_fun_nonempty_list { List.rev $1 }
	| { [] }
;

/* Declaration function list */
decl_fun_nonempty_list:
  | decl_fun_def { [$1] }
  | decl_fun_nonempty_list decl_fun_def { $2 :: $1 }
;

/* Function definition */
decl_fun_def:
  | CT_FUN NAME LPAREN fun_parameter_list RPAREN COLON var_type_discrete CT_BEGIN seq_code_bloc return_opt CT_END
  {
    {
      name = $2;
      parameters = List.rev $4;
      return_type = $7;
      body = $9, $10;
    }
  }
;

return_opt:
  | CT_RETURN boolean_expression semicolon_opt { Some $2 }
  | { None }
;

fun_parameter_list:
  | { [] }
  | fun_parameter_nonempty_list { $1 }
;

/* Function parameters list (separated by whitespace) */
fun_parameter_nonempty_list:
  | NAME COLON var_type_discrete { [(($1, Parsing.symbol_start ()), $3)] }
  | fun_parameter_list COMMA NAME COLON var_type_discrete { (($3, Parsing.symbol_start ()), $5) :: $1 }
;

seq_code_bloc:
  | { [] }
  | seq_code_bloc_nonempty_list { $1 }
;

/* Bloc of code (instructions, declarations, conditionals, loops) */
seq_code_bloc_nonempty_list:
  | instruction semicolon_or_comma seq_code_bloc_nonempty_list { $1 :: $3 }
  | control_structure seq_code_bloc_nonempty_list { $1 :: $2 }
  | instruction semicolon_or_comma_opt { [$1] }
  | control_structure { [$1] }
;

semicolon_or_comma_opt:
  | {}
  | semicolon_or_comma {}
;

instruction:
  /* local declaration */
  | CT_VAR NAME COLON var_type_discrete OP_EQ boolean_expression { Parsed_local_decl (($2, Parsing.symbol_start ()), $4, $6) }
  /* assignment */
  | update_without_deprecated { (Parsed_assignment $1) }
  /* instruction without return */
  | boolean_expression { (Parsed_instruction $1) }

;



/** Normal updates without deprecated (avoid parsing errors on function)*/
update_without_deprecated:
	| parsed_scalar_or_index_update_type OP_ASSIGN boolean_expression { $1, $3 }
;

/* Variable or variable access */
parsed_scalar_or_index_update_type:
  | NAME { Parsed_scalar_update ($1, 0) }
  | parsed_scalar_or_index_update_type LSQBRA arithmetic_expression RSQBRA { Parsed_indexed_update ($1, $3) }
;


control_structure:
  /* for loop */
  | CT_FOR NAME CT_FROM arithmetic_expression loop_dir arithmetic_expression CT_DO seq_code_bloc CT_DONE { Parsed_for_loop (($2, Parsing.symbol_start ()), $4, $6, $5, $8) }
  /* while loop */
  | CT_WHILE boolean_expression CT_DO seq_code_bloc CT_DONE { Parsed_while_loop ($2, $4) }
  /* conditional */
  | CT_IF boolean_expression CT_THEN seq_code_bloc CT_END { Parsed_if ($2, $4, None) }
  | CT_IF boolean_expression CT_THEN LPAREN seq_code_bloc RPAREN CT_END { Parsed_if ($2, $5, None) }
  | CT_IF boolean_expression CT_THEN seq_code_bloc CT_ELSE seq_code_bloc CT_END { Parsed_if ($2, $4, Some $6) }
  | CT_IF boolean_expression CT_THEN LPAREN seq_code_bloc RPAREN CT_ELSE LPAREN seq_code_bloc RPAREN CT_END { Parsed_if ($2, $5, Some $9) }
;

loop_dir:
  | CT_TO { Parsed_for_loop_up }
  | CT_DOWNTO { Parsed_for_loop_down }
;

/************************************************************/

/************************************************************
  AUTOMATA
************************************************************/

/************************************************************/

automata:
	| automaton automata { $1 :: $2 }
	| include_file automata { include_list := $1 :: !include_list; $2 }
	| { [] }
;



/************************************************************/

automaton:
	| CT_AUTOMATON NAME prolog locations CT_END
	{
		($2, $3, $4)
	}
;

/************************************************************/

prolog:
	| sync_labels { $1 }
	| { [] }
;

/************************************************************/


/************************************************************/

sync_labels:
	| CT_ACTIONS COLON name_list SEMICOLON { $3 }
	/** NOTE: deprecated since 3.4 */
	| CT_SYNCLABS COLON name_list SEMICOLON {
			print_warning ("The syntax `synclabs` is deprecated since version 3.4; please use `actions` instead.");
	$3 }
;

/************************************************************/

name_list:
	| name_nonempty_list { $1 }
	| { [] }
;

/************************************************************/

name_nonempty_list:
	NAME COMMA name_nonempty_list { $1 :: $3}
	| NAME comma_opt { [$1] }
;

/************************************************************/

locations:
	location locations { $1 :: $2}
	| { [] }
;

/************************************************************/


location:
	| loc_urgency_accepting_type location_name_and_costs COLON while_or_invariant_or_nothing nonlinear_convex_predicate stopwatches_and_flow_opt wait_opt transitions {
		let urgency, accepting = $1 in
		let name, cost = $2 in
		let stopwatches, flow = $6 in
		{
			(* Name *)
			name		= name;
			(* Urgent or not? *)
			urgency		= urgency;
			(* Accepting or not? *)
			acceptance	= accepting;
			(* Cost *)
			cost		= cost;
			(* Invariant *)
			invariant	= $5;
			(* List of stopped clocks *)
			stopped		= stopwatches;
			(* Flow of clocks *)
			flow		= flow;
			(* Transitions starting from this location *)
			transitions = $8;
		}
	}
;


loc_urgency_accepting_type:
	| CT_LOC { Parsed_location_nonurgent, Parsed_location_nonaccepting }
	| CT_URGENT CT_LOC { Parsed_location_urgent, Parsed_location_nonaccepting }
	| CT_ACCEPTING CT_LOC { (Parsed_location_nonurgent, Parsed_location_accepting) }
	| CT_URGENT CT_ACCEPTING CT_LOC { (Parsed_location_urgent, Parsed_location_accepting) }
	| CT_ACCEPTING CT_URGENT CT_LOC { (Parsed_location_urgent, Parsed_location_accepting) }
;

location_name_and_costs:
	| NAME { $1, None }
	| NAME LSQBRA linear_expression RSQBRA { $1, Some $3 }
;

while_or_invariant_or_nothing:
	/* From 2018/02/22, "while" may be be replaced with invariant */
	/* From 2019/12, "while" should be be replaced with invariant */
	| CT_WHILE {
		print_warning ("The syntax `while [invariant]` is deprecated; you should use `invariant [invariant]` instead.");
		()
		}
	| CT_INVARIANT {}
	| {}
;

wait_opt:
	| CT_WAIT {
			print_warning ("The syntax `wait` in invariants is deprecated.");
		()
	}
	| CT_WAIT LBRACE RBRACE {
			print_warning ("The syntax `wait {}` in invariants is deprecated.");
		()
	}
	/* Now deprecated and not accepted anymore */
/* 	| LBRACE RBRACE { } */
	| { }
;


/************************************************************/

stopwatches_and_flow_opt:
	| stopwatches flow { $1, $2 }
	| flow stopwatches { $2, $1 }
	| stopwatches { $1, [] }
	| flow { [], $1 }
	| { [], [] }
;

/************************************************************/

flow:
	| CT_FLOW LBRACE flow_list RBRACE { $3 }
;


/************************************************************/

flow_list:
	| flow_nonempty_list { $1 }
	| { [] }
;

/************************************************************/

flow_nonempty_list:
	| single_flow COMMA flow_nonempty_list { $1 :: $3 }
	| single_flow comma_opt { [$1] }
;

/************************************************************/

single_flow:
	| NAME APOSTROPHE OP_EQ rational_linear_expression { ($1, $4) }
;

/************************************************************/

stopwatches:
	| CT_STOP LBRACE name_list RBRACE { $3 }
;

/************************************************************/

transitions:
	| transition transitions { $1 :: $2 }
	| { [] }
;

/************************************************************/

transition:
	| CT_WHEN nonlinear_convex_predicate update_synchronization CT_GOTO NAME SEMICOLON
	{
		let update_list, sync = $3 in
			$2, update_list, sync, $5
	}
;

/************************************************************/

/* A l'origine de 3 conflits ("2 shift/reduce conflicts, 1 reduce/reduce conflict.") donc petit changement */
update_synchronization:
	| { [], NoSync }
	| updates { $1, NoSync }
	| sync_label { [], (Sync $1) }
	| updates sync_label { $1, (Sync $2) }
	| sync_label updates { $2, (Sync $1) }
;

/************************************************************/

updates:
  | CT_DO LBRACE seq_code_bloc RBRACE { $3 }
;

/************************************************************/

sync_label:
	CT_SYNC NAME { $2 }
;



/************************************************************/
/** INIT DEFINITION */
/************************************************************/

init_definition_option:
    | old_init_definition {
		(* Print a warning because this syntax is deprecated *)
		print_warning ("Old syntax detected for the initial state definition. You are advised to use the new syntax (from 3.1).");
		$1
		}
    | init_definition { $1 }
    | { [ ] }
;

/************************************************************/
/** OLD INIT DEFINITION SECTION <= 3.0: DISCRETE AND CONTINUOUS mixed together */
/************************************************************/

/* Old init style (until 3.0), kept for backward-compatibility */
old_init_definition:
	| CT_INIT OP_ASSIGN old_init_expression SEMICOLON { $3 }
;


/* We allow here an optional "&" at the beginning and at the end */
old_init_expression:
	| ampersand_opt old_init_expression_fol ampersand_opt { $2 }
	| { [ ] }
;

old_init_expression_fol:
	| old_init_state_predicate { [ $1 ] }
	| LPAREN old_init_expression_fol RPAREN { $2 }
	| old_init_expression_fol AMPERSAND old_init_expression_fol { $1 @ $3 }
;

/* Used in the init definition */
old_init_state_predicate:
	| old_init_loc_predicate { let a,b = $1 in (Parsed_loc_assignment (a,b)) }
    | linear_constraint { Parsed_linear_predicate $1 }
;

old_init_loc_predicate:
	/* loc[my_pta] = my_loc */
	| CT_LOC LSQBRA NAME RSQBRA OP_EQ NAME { ($3, $6) }
	/* my_pta IS IN my_loc */
	| NAME CT_IS CT_IN NAME { ($1, $4) }
;




/************************************************************/
/** NEW INIT DEFINITION SECTION from 3.1: SEPARATION OF DISCRETE AND CONTINUOUS */
/************************************************************/

init_definition:
	| CT_INIT OP_ASSIGN LBRACE init_discrete_continuous_definition RBRACE semicolon_opt { $4 }
;

init_discrete_continuous_definition:
    | init_discrete_definition { $1 }
    | init_continuous_definition { $1 }
    | init_discrete_definition init_continuous_definition { $1 @ $2 }
    | init_continuous_definition init_discrete_definition { $2 @ $1 }
;

init_discrete_definition:
    | CT_DISCRETE OP_EQ init_discrete_expression SEMICOLON { $3 }
;

init_continuous_definition:
    | CT_CONTINUOUS OP_EQ init_continuous_expression SEMICOLON { $3 }
;


init_discrete_expression:
	| comma_opt init_discrete_expression_nonempty_list { $2 }
	| { [ ] }
;

init_discrete_expression_nonempty_list :
	| init_discrete_state_predicate COMMA init_discrete_expression_nonempty_list  { $1 :: $3 }
	| init_discrete_state_predicate comma_opt { [ $1 ] }
;

init_discrete_state_predicate:
	| init_loc_predicate { let a,b = $1 in (Parsed_loc_assignment (a,b)) }
	| LPAREN init_discrete_state_predicate  RPAREN { $2 }
	| NAME OP_ASSIGN boolean_expression { Parsed_discrete_predicate ($1, $3) }
;

init_continuous_expression:
	| ampersand_opt init_continuous_expression_nonempty_list { $2 }
	| { [ ] }
;

init_continuous_expression_nonempty_list :
	| init_continuous_state_predicate AMPERSAND init_continuous_expression_nonempty_list  { $1 :: $3 }
	| init_continuous_state_predicate ampersand_opt { [ $1 ] }
;

init_continuous_state_predicate:
    | LPAREN init_continuous_state_predicate RPAREN { $2 }
    | linear_constraint { Parsed_linear_predicate $1 }
;

init_loc_predicate:
	/* loc[my_pta] = my_loc */
	| CT_LOC LSQBRA NAME RSQBRA OP_ASSIGN NAME { ($3, $6) }
	/* my_pta IS IN my_loc */
	| NAME CT_IS CT_IN NAME { ($1, $4) }
;



/************************************************************/
/** ARITHMETIC EXPRESSIONS */
/************************************************************/

arithmetic_expression:
	| arithmetic_term { Parsed_term $1 }
	| arithmetic_expression sum_diff arithmetic_term { Parsed_sum_diff ($1, $3, $2) }
;

sum_diff:
  | OP_PLUS { Parsed_plus }
  | OP_MINUS { Parsed_minus }
;

/* Term over variables and rationals (includes recursion with arithmetic_expression) */
arithmetic_term:
	| arithmetic_factor { Parsed_factor $1 }
	/* Shortcut for syntax rational NAME without the multiplication operator */
	| number NAME { Parsed_product_quotient (Parsed_factor (Parsed_constant ($1)), Parsed_variable ($2, 0), Parsed_mul) }
	| arithmetic_term product_quotient arithmetic_factor { Parsed_product_quotient ($1, $3, $2) }
	| arithmetic_term product_quotient arithmetic_factor { Parsed_product_quotient ($1, $3, $2) }
	| OP_MINUS arithmetic_factor { Parsed_factor(Parsed_unary_min $2) }
;

product_quotient:
  | OP_MUL { Parsed_mul }
  | OP_DIV { Parsed_div }
;

/*
postfix_arithmetic_factor:
  | arithmetic_factor { Parsed_factor $1 }
  | postfix_arithmetic_factor LSQBRA pos_integer RSQBRA { Parsed_access ($1, NumConst.to_int $3) }
;
*/

arithmetic_factor:
  | arithmetic_factor LSQBRA arithmetic_expression RSQBRA { Parsed_access ($1, $3) }
  | NAME LPAREN function_argument_fol RPAREN { Parsed_function_call ($1, $3) }
  | literal_scalar_constant { Parsed_constant $1 }
  | literal_non_scalar_constant { $1 }
  | NAME { Parsed_variable ($1, 0) }
  | LPAREN arithmetic_expression RPAREN { Parsed_nested_expr $2 }
;

literal_scalar_constant:
  | number { $1 }
  | CT_TRUE { ParsedValue.Bool_value true }
  | CT_FALSE { ParsedValue.Bool_value false }
  | binary_word { $1 }
;

literal_non_scalar_constant:
  | literal_array { Parsed_sequence ($1, Parsed_array) }
  | CT_LIST LPAREN literal_array RPAREN { Parsed_sequence ($3, Parsed_list) }
  | CT_STACK LPAREN RPAREN { Parsed_sequence ([], Parsed_stack) }
  | CT_QUEUE LPAREN RPAREN { Parsed_sequence ([], Parsed_queue) }
;

literal_array:
  /* Empty array */
  | LSQBRA RSQBRA { [] }
  /* Non-empty array */
  | LSQBRA literal_array_fol RSQBRA { $2 }
;

literal_array_fol:
	| boolean_expression COMMA literal_array_fol { $1 :: $3 }
	| boolean_expression { [$1] }
;

function_argument_fol:
  | boolean_expression COMMA function_argument_fol { $1 :: $3 }
  | boolean_expression { [$1] }
  | { [] }
;

number:
	| integer { ParsedValue.Weak_number_value $1 }
	| float { ParsedValue.Rat_value $1 }
	/*| integer OP_DIV pos_integer { ( ParsedValue.Rat_value (NumConst.div $1 $3)) }*/
;

binary_word:
        BINARYWORD { ParsedValue.Bin_value (BinaryWord.binaryword_of_string $1) }
;

/************************************************************/
/** RATIONALS, LINEAR TERMS, LINEAR CONSTRAINTS AND CONVEX PREDICATES */
/************************************************************/

/* We allow an optional "&" at the beginning of a convex predicate (sometimes useful) */
nonlinear_convex_predicate:
	| ampersand_opt nonlinear_convex_predicate_fol { $2 }
;

nonlinear_convex_predicate_fol:
	| discrete_boolean_expression AMPERSAND nonlinear_convex_predicate { $1 :: $3 }
	| discrete_boolean_expression { [$1] }
;


/* Linear expression over variables and rationals */
linear_expression:
	| linear_term { Linear_term $1 }
	| linear_expression OP_PLUS linear_term { Linear_plus_expression ($1, $3) }
	| linear_expression OP_MINUS linear_term { Linear_minus_expression ($1, $3) } /* linear_term a la deuxieme place */
;

/* Linear term over variables and rationals (no recursion, no division) */
linear_term:
	| rational { Constant $1 }
	| rational NAME { Variable ($1, $2) }
	| rational OP_MUL NAME { Variable ($1, $3) }
	| OP_MINUS NAME { Variable (NumConst.minus_one, $2) }
	| NAME { Variable (NumConst.one, $1) }
	| LPAREN linear_term RPAREN { $2 }
;


/* Linear expression over rationals only */
rational_linear_expression:
	| rational_linear_term { $1 }
	| rational_linear_expression OP_PLUS rational_linear_term { NumConst.add $1 $3 }
	| rational_linear_expression OP_MUL rational_linear_term { NumConst.mul $1 $3 }
	| rational_linear_expression OP_DIV rational_linear_term { NumConst.div $1 $3 }
	| rational_linear_expression OP_MINUS rational_linear_term { NumConst.sub $1 $3 } /* linear_term a la deuxieme place */
;

/* Linear term over rationals only */
rational_linear_term:
	| rational { $1 }
	| OP_MINUS rational_linear_term { NumConst.neg $2 }
	| LPAREN rational_linear_expression RPAREN { $2 }
;

linear_constraint:
	| linear_expression relop linear_expression { Parsed_linear_constraint ($1, $2, $3) }
	| CT_TRUE { Parsed_true_constraint }
	| CT_FALSE { Parsed_false_constraint }
;


/************************************************************/
/** BOOLEAN EXPRESSIONS */
/************************************************************/

/** NOTE: more general than a Boolean expression!! notably includes all expressions */
boolean_expression:
	| discrete_boolean_expression { Parsed_discrete_bool_expr $1 }
	| boolean_expression AMPERSAND boolean_expression { Parsed_conj_dis ($1, $3, Parsed_and) }
  | boolean_expression PIPE boolean_expression { Parsed_conj_dis ($1, $3, Parsed_or) }
;

discrete_boolean_expression:
	| arithmetic_expression { Parsed_arithmetic_expr $1 }
	/* Discrete arithmetic expression of the form Expr ~ Expr */
	| discrete_boolean_expression relop discrete_boolean_expression { Parsed_comparison ($1, $2, $3) }
	/* Discrete arithmetic expression of the form 'Expr in [Expr, Expr ]' */
	| arithmetic_expression CT_INSIDE LSQBRA arithmetic_expression COMMA arithmetic_expression RSQBRA { Parsed_comparison_in ($1, $4, $6) }
	/* allowed for convenience */
	| arithmetic_expression CT_INSIDE LSQBRA arithmetic_expression SEMICOLON arithmetic_expression RSQBRA { Parsed_comparison_in ($1, $4, $6) }
	/* Parsed boolean expression of the form Expr ~ Expr, with ~ = { &, | } or not (Expr) */
	| LPAREN boolean_expression RPAREN { Parsed_nested_bool_expr $2 }
	| CT_NOT LPAREN boolean_expression RPAREN { Parsed_not $3 }
;

relop:
	| OP_L { PARSED_OP_L }
	| OP_LEQ { PARSED_OP_LEQ }
	| OP_EQ { PARSED_OP_EQ }
	| OP_NEQ { PARSED_OP_NEQ }
	| OP_GEQ { PARSED_OP_GEQ }
	| OP_G { PARSED_OP_G }
;


/************************************************************/
/** NUMBERS */
/************************************************************/

rational:
	| integer { $1 }
	| float { $1 }
	| integer OP_DIV pos_integer { (NumConst.div $1 $3) }
;

integer:
	| pos_integer { $1 }
	| OP_MINUS pos_integer { NumConst.neg $2 }
;

pos_integer:
	| INT { $1 }
;

float:
	| pos_float { $1 }
	| OP_MINUS pos_float { NumConst.neg $2 }
;

pos_float:
  FLOAT {
		NumConst.numconst_of_string $1
	}
;

/************************************************************/
/** MISC. */
/************************************************************/

semicolon_or_comma:
  | SEMICOLON {}
  | COMMA {}
;

comma_opt:
	| COMMA { }
	| { }
;

semicolon_opt:
	| SEMICOLON { }
	| { }
;

ampersand_opt:
	| AMPERSAND { }
	| { }
;
