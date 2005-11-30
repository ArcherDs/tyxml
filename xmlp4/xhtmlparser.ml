(* Ocsigen
 * Copyright (C) 2005 Vincent Balat
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

(* 
   Parseur camlp4 pour XHTML

   Attention c'est juste un essai
   Je ne colle peut-�tre pas � la syntaxe XML
   par ex il faut revoir si un attribut peut �tre vide en xml
   Si oui, il faut remplacer le "string" par "string option"

   Le typage des attributs n'est pas evident donc pour l'instant ils sont tous string
   exemple << <plop number="5" /> >> ----> `Number 5  (en fait `Number (int_of_string "5"))
           << <plop number=$n$ /> >> ----> `Number n o`u n est de type int ??? 

On pourrait decider d'ecrire << <plop number=$string_of_int n$ /> >>
Mais du coup cela fait int_of_string (string_of_int n) 
et ensuite encore string_of_int au moment de l'affichage

   Revoir aussi la gestion des commentaires ?

� revoir 

*)



open Pcaml


let blocktags = [ "fieldset"; "form"; "address"; "body"; "head"; "blockquote"; "div"; "html"; "h1"; "h2"; "h3"; "h4"; "h5"; "h6"; "p"; "dd"; "dl"; "li"; "ol"; "ul"; "colgroup"; "table"; "tbody"; "tfoot"; "thead"; "td"; "th"; "tr" ]

let semiblocktags = [ "pre"; "style"; "title" ]



(* Instead of using Pcaml.gram, we use a new grammar, using xmllexer *)
let g = Grammar.gcreate (Xmllexer.gmake ())


module ExpoOrPatt = struct

  let loc = (Lexing.dummy_pos, Lexing.dummy_pos)

  type tvarval =
      EPVstr of string
    | EPVvar of string 

  type 'a tlist =
      PLEmpty
    | PLVar of string
    | PLCons of 'a * 'a tlist

  type texprpatt = 
      EPanyattr of tvarval * tvarval
    | EPanytag of string * texprpatt tlist * texprpatt tlist
    | EPpcdata of string
    | EPwhitespace of string
    | EPcomment of string
    | EPanytagvar of string
    | EPanytagvars of string

  let list_of_mlast_expr el = 
    List.fold_right 
      (fun x l -> <:expr< [$x$ :: $l$] >>) el <:expr< [] >>

  let list_of_mlast_patt pl = 
    List.fold_right 
      (fun x l -> <:patt< [$x$ :: $l$] >>) pl <:patt< [] >>

  let expr_valorval = function
      EPVstr v -> <:expr< $str:v$ >>
    | EPVvar v -> <:expr< $lid:v$ >>

  let patt_valorval = function
      EPVstr v -> <:patt< $str:v$ >>
    | EPVvar v -> <:patt< $lid:v$ >>

  let rec to_expr = function

      EPanyattr (EPVstr aa, v) ->
	let vv = expr_valorval v in
	<:expr< ($str:aa$, $vv$) >>

    | EPanyattr (EPVvar aa, v) ->
	let vv = expr_valorval v in
	<:expr< ($lid:aa$, $vv$) >>

    | EPanytag (tag, attribute_list, child_list) ->
	let constr =
	  if List.mem tag blocktags
	  then "BlockElement"
	  else (if List.mem tag semiblocktags
	  then "SemiBlockElement"
	  else "Element")
	in
	(match child_list with
	  PLEmpty ->
	    <:expr< ((Xhtml.tot (Xhtml.$uid:constr$ $str:tag$
                $to_expr_attlist attribute_list$
		[])) : Xhtml.t [> `$uid: String.capitalize tag$])
            >>
	| _ ->
	    <:expr< ((Xhtml.tot (Xhtml.$uid:constr$ $str:tag$
               $to_expr_attlist attribute_list$
               (Xhtml.toeltl ($to_expr_taglist child_list$ :> list (Xhtml.t [< Xhtml.$lid:"xh"^tag^"cont"$])))))
		   : Xhtml.t [> `$uid: String.capitalize tag$])
	    >>)
	
    | EPpcdata dt -> <:expr< ((Xhtml.tot (Xhtml.Pcdata $str:dt$)) : Xhtml.t [> Xhtml.pcdata ]) >>

    | EPwhitespace dt -> <:expr< Xhtml.tot (Xhtml.Whitespace $str:dt$) >>

    | EPanytagvar v -> <:expr< $lid:v$ >>

    | EPanytagvars v -> <:expr< ((Xhtml.tot (Xhtml.Pcdata $lid:v$)) : Xhtml.t [> Xhtml.pcdata ]) >>

    | EPcomment c -> <:expr< Xhtml.tot (Xhtml.Comment $str:c$) >>

  and to_expr_taglist = function
      PLEmpty -> <:expr< [] >>
    | PLVar v -> <:expr< $lid:v$ >>
    | PLCons (a,l) -> <:expr< [ $to_expr a$ :: $to_expr_taglist l$ ] >>

  and to_expr_attlist = function
      PLEmpty -> <:expr< [] >>
    | PLVar v -> <:expr< $lid:v$ >>
    | PLCons (a,l) -> <:expr< [ $to_expr a$ :: $to_expr_attlist l$ ] >>


  let rec to_patt = function

      EPanyattr (EPVstr a, v) -> 
	let vv = patt_valorval v in
	<:patt< (($str:a$), $vv$) >>

    | EPanyattr (EPVvar a, v) ->
	let vv = patt_valorval v in
	<:patt< ($lid:a$, $vv$) >>

    | EPanytag (tag, attribute_list, child_list) ->
	<:patt< Element $str:tag$
	  $to_patt_attlist attribute_list$
          $to_patt_taglist child_list$
        >>

    | EPpcdata dt -> <:patt< Pcdata $str:dt$ >>

    | EPwhitespace dt -> <:patt< Whitespace $str:dt$ >>

    | EPanytagvar v -> <:patt< $lid:v$ >>

    | EPanytagvars v -> <:patt< Pcdata $lid:v$ >>

    | EPcomment c -> <:patt< Comment $str:c$ >>

  and to_patt_taglist = function
      PLEmpty -> <:patt< [] >>
    | PLVar v -> <:patt< $lid:v$ >>
    | PLCons (a,l) -> <:patt< [ $to_patt a$ :: $to_patt_taglist l$ ] >>

  and to_patt_attlist = function
      PLEmpty -> <:patt< [] >>
    | PLVar v -> <:patt< $lid:v$ >>
    | PLCons (a,l) -> <:patt< [ $to_patt a$ :: $to_patt_attlist l$ ] >>

end

open ExpoOrPatt

let exprpatt_xml = Grammar.Entry.create g "xml"
let exprpatt_any_tag = Grammar.Entry.create g "xml tag"
let exprpatt_any_tag_list = Grammar.Entry.create g "xml tag list"
let exprpatt_any_attribute_list = Grammar.Entry.create g "xml attribute list"
let exprpatt_attr_or_var = Grammar.Entry.create g "xml attribute or $var$"
let exprpatt_value_or_var = Grammar.Entry.create g "xml value or $var$"


EXTEND

  exprpatt_xml:
  [ [
    declaration_list = LIST0 [ DECL | XMLDECL ];
    OPT WHITESPACE;
    root_tag = exprpatt_any_tag;
    OPT WHITESPACE;
    EOI -> root_tag
  ] ];

  exprpatt_any_tag:
  [ [
    tag = TAG;
    attribute_list = OPT exprpatt_any_attribute_list;
    child_list = OPT exprpatt_any_tag_list;
    GAT -> 
      let attlist = match attribute_list with
	  None -> PLEmpty
	| Some l -> l
      in
      let taglist = match child_list with
	  None -> PLEmpty
	| Some l -> l
      in EPanytag
	(tag,
	 attlist, 
	 taglist)
  | dt = WHITESPACE -> EPwhitespace dt
  | dt = DATA -> EPpcdata dt
  | c = COMMENT -> EPcomment c
  | v = CAMLVARXML -> EPanytagvar v
  | v = CAMLVARXMLS -> EPanytagvars v
  ] ];

  exprpatt_any_attribute_list:
  [ [
      v = CAMLVARL -> PLVar v
    | a = exprpatt_attr_or_var;
      "=";
      value = exprpatt_value_or_var;
      suite  = OPT exprpatt_any_attribute_list ->
      let suite = match suite with
	  None -> PLEmpty
	| Some l -> l
      in PLCons (EPanyattr (a,value), suite)
  ] ];

  exprpatt_any_tag_list:
  [ [
      v = CAMLVARXMLL;
      OPT WHITESPACE -> PLVar v
    | anytag = exprpatt_any_tag;
      suite  = OPT exprpatt_any_tag_list ->
      let suite = match suite with
	  None -> PLEmpty
	| Some l -> l
      in PLCons (anytag, suite)
  ] ];

  exprpatt_value_or_var:
  [ [
    v = VALUE -> EPVstr v
  | v = CAMLVAR -> EPVvar v
  ] ];

  exprpatt_attr_or_var:
  [ [
    v = ATTR -> EPVstr v
  | v = CAMLVAR -> EPVvar v
  ] ];

END;;

let xml_exp s = to_expr (Grammar.Entry.parse exprpatt_xml (Stream.of_string s))

(*  let ep = Grammar.Entry.parse exprpatt_xml (Stream.of_string s) in
  match ep with
    EPanytag (tag,_,_) -> <:expr< (($to_expr ep$) : Xhtml.t [= `$uid: String.capitalize tag$]) >>
  | _ -> failwith "Prepocessor error in xhtmlparser: there must be only one root tag"
*)

let xml_pat s = to_patt (Grammar.Entry.parse exprpatt_xml (Stream.of_string s))

let xmlparser s =
  let chan = open_in s in
  let tree = Grammar.Entry.parse exprpatt_any_tag_list (Stream.of_channel chan) in
  close_in chan;
  tree



(*
(* Pour les expressions et les patterns on peut �crire *)
let a = << a >> in
let b = << bb >> in
let c = `Cc in
let d = "dd" in
let e = `Ee in
let f = "ff" in
let g = << <ark> </ark> >> in
let s = << <youpi> $a$ $b$ $$ $g$ <bobo $c$=$d$ $e$=$f$> </bobo> </youpi> >> in
let la = [(`A, "popo");(`Ggg, "lkjl")] in
let l = [<< <ark $c$=$f$ %la%> </ark> >>; << <wow> </wow> >>] in
  << <youpi> $a$ zzz %l% </youpi> >>
(* $$ permet d'�crire un $ *)
(* %% permet d'�crire un % *)

function << <html %l1%> $a$ ljl %l2% </html> >> -> 1 | _ -> 2
function << <html $n$=$v$ a="b" %l1%> <body> %l2% </body> </html> >> 
    -> 1 | _ -> 2
function << <html %l1%> <body> %l2% </body> %l3% </html> >> -> 1 | _ -> 2
(*
(* mais pas : *)
fun << <html %l1%> %l2% %l3% </html> >> -> 1
(* ni : *)
fun << <html %l1%> %l2% $a$ </html> >> -> 1
(* ni : *)
fun << <html %l1%> %l3% <body> %l2% </body> </html> >> -> 1
(* car les %l% sont des listes *)
*)
*)
