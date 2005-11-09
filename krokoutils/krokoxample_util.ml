(* Copyright Vincent Balat 2005 *)
(** An example of Kroko module using Krokoutils *)


open Kroko
open Krokodata
open Krokopages
open Krokosavable
open Krokoboxes
open Rights


(******************************************************************)
(* -- Here I populate the database with some examples: *)

let rkrokexample =  Krokopersist.get
    (Krokopersist.make_persistant_lazy "rkrokexample"
       (fun () -> create_resource ()))

let messageslist_number =
  Krokopersist.get
    (Krokopersist.make_persistant_lazy "krokoxample_messageslist_number"
       (fun () -> 
	  StringMessageIndexList.dbinsert
	   ~rights:([anonymoususer],[root],[rkrokexample],[rkrokexample]) 
	    [StringMessage.dbinsert 
	       ~rights:([anonymoususer],[root],[rkrokexample],[rkrokexample]) 
	       "Ceci est un premier message. Blabla blabla blabla blabla. Blabla blabla blabla blabla.";
	     StringMessage.dbinsert 
	       ~rights:([anonymoususer],[root],[rkrokexample],[rkrokexample]) 
	       "Ceci est un deuxi�me message. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla.";
	     StringMessage.dbinsert
	       ~rights:([anonymoususer],[root],[rkrokexample],[rkrokexample]) 
	       "Ceci est un troisi�me message. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla.";
	     StringMessage.dbinsert 
	       ~rights:([anonymoususer],[root],[rkrokexample],[rkrokexample]) 
	       "Ceci est un quatri�me message. Blabla blabla blabla blabla.";
	     StringMessage.dbinsert
	       ~rights:([anonymoususer],[root],[rkrokexample],[rkrokexample]) 
	       "Ceci est un cinqui�me message. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla.";
	     StringMessage.dbinsert
	       ~rights:([anonymoususer],[root],[rkrokexample],[rkrokexample]) 
	       "Ceci est un sixi�me message. Blabla blabla blabla blabla. Blabla blabla blabla blabla.";
	     StringMessage.dbinsert
	       ~rights:([anonymoususer],[root],[rkrokexample],[rkrokexample]) 
	       "Ceci est un septi�me message. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla. Blabla blabla blabla blabla."])
    )


(* An user *)
let toto_created =
  Krokopersist.make_persistant_lazy "toto_created"
  (fun () -> 
     ignore (create_user 
	       ~login:"toto" ~name:"Toto" ~password:"titi" ~groups:[users] ());
     true)

(* -- End population of the database with an example *)



(******************************************************************)
(* My boxes *)

(** A box that prints the beginning of a message, with a link to the 
    full message *)
let news_header_box httpparam key user resource news_page = 
  let msg = StringMessage.dbget user resource key
  in let l = link "read" httpparam.current_url news_page key
  in << <div> $str:msg$ $l$ <br/> </div> >>

(** A box that prints a list of a message headers *)
let news_headers_list_box httpparam key user resource news_page = 
  let msglist = 
    List.map 
      (fun n -> news_header_box httpparam n user resource news_page)
      (StringMessageIndexList.dbget user resource key)
  in << <div>$list:msglist$</div> >>


