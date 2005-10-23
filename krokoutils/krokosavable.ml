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
    type content = Xhtmlpp.xhtmlcont
    type 'a t = 'a
    type box = [`Box of content t tfolded]
    type boxes = box
    let name = "boxes"
    let tag x = `Box x
    let untag (`Box x) = x
    let default_handler = box_exn_handler
      let make_boxofboxes ~filter l = 
	List.map (fun b -> (filter b)) l
    type container_param = string option * string option
    let container f ~box_param:((classe,id),l) = 
      boxes_container ?classe:classe ?id:id (f ~user:Rights.anonymoususer l)
  end)

let fold_boxes = 
  RegisterBoxes.register_unfolds
    ~box_constructor:RegisterBoxes.unfold

(* Then register all constructors in the right register *)
let fold_title_box = 
  RegisterBoxes.register 
    ~name:"title_box" 
    ~constructor:(fun ~box_param -> title_box box_param)

let fold_text_box = 
  RegisterBoxes.register 
    ~name:"text_box" ~constructor:(fun ~box_param -> text_box box_param)




