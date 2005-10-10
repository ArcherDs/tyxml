open Krokodata
open Krokopages

(******************************************************************)
(* Tools to save boxes and pages in the database *)

(*
J'ai essay� aussi de param�trer les constructeurs par la classe de bo�tes
� utiliser pour choisir la classe de bo�te au moment du chargement de la page
depuis la base de donn�es, et non au moment de sa sauvegarde.
mais ce n'est pas terrible parce que du coup on ne peut plus rajouter
de nouvelles bo�tes dans une page sans cr�er un nouveau Register de bo�tes 
� chaque fois...
*)


(* First of all, we create a register for all kind of pages we want *)
module RegisterBoxes =
  MakeRegister(struct 
		 type t = Xhtmlpp.xhtmlcont
		 let name = "boxes"
		 let default_handler = box_exn_handler
		 let default_tables = []
	       end)


(* Then register all constructors in the right register *)
let fold_title_box = 
  RegisterBoxes.register 
    ~name:"title_box" 
    ~constructor:(fun ~box_param -> title_box box_param)

let fold_text_box = 
  RegisterBoxes.register 
    ~name:"text_box" ~constructor:(fun ~box_param -> text_box box_param)




