(*****************************************************************
 *
 *                       IMITATOR
 * 
 * Université Paris 13, LIPN, CNRS, France
 * 
 * Author:        Etienne Andre
 * 
 * Created:       2014/09/24
 * Last modified: 2016/03/18
 *
 ****************************************************************)

(** Global function: set the number of dimensions for ALL hyper rectangles; must be called (once and only once) before creating any object *)
val set_dimensions : int -> unit

(** Global function: get the number of dimensions for ALL hyper rectangles *)
val get_dimensions : unit -> int


class hyper_rectangle :
	object
		
		(** Get the minimum value for a dimension *)
		method get_min : int -> NumConst.t
		(** Get the maximum value for a dimension *)
		method get_max : int -> NumConst.t

		(** Set the minimum value for a dimension *)
		method set_min : int -> NumConst.t -> unit
		(** Set the maximum value for a dimension *)
		method set_max : int -> NumConst.t -> unit

		(** Get the smallest point in the hyper rectangle (i.e., the list of min) in the form of a PVal.pval *)
		method get_smallest_point : unit -> PVal.pval
		
		(** Compute the (actually slightly approximated) number of points in V0 (for information purpose) *)
		(*** NOTE: why slightly approximated??? when step is used? ***)
		method get_nb_points : NumConst.t -> NumConst.t

		
		
end
