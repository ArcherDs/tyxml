(* Ocsigen
 * Copyright (C) 2005 Vincent Balat
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception; 
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

(* 
   Parseur camlp4 pour XML

   Attention c'est juste un essai
   Je ne colle peut-�tre pas � la syntaxe XML

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

(* Instead of using Pcaml.gram, we use a new grammar, using xmllexer *)
let g = Grammar.gcreate (Xmllexer.gmake ())


module ExpoOrPatt = struct

  type tvarval =
      EPVstr of string * MLast.loc
    | EPVvar of string * MLast.loc 

  type 'a tlist =
      PLEmpty of MLast.loc
    | PLExpr of string * MLast.loc
    | PLCons of 'a * 'a tlist * MLast.loc

  type texprpatt = 
      EPanyattr of tvarval * tvarval * MLast.loc
    | EPanytag of string * texprpatt tlist * texprpatt tlist * MLast.loc
    | EPpcdata of string * MLast.loc
    | EPwhitespace of string * MLast.loc
    | EPcomment of string * MLast.loc
    | EPanytagvar of string * MLast.loc
    | EPanytagvars of string * MLast.loc

  let get_expr v = (* <:expr< $lid:v$ >> *)
    match (!Pcaml.parse_implem) (Stream.of_string v) with
      [MLast.StExp (v,w), loc],_ -> (* w *)
(*        let w = Pcaml.expr_reloc (fun x -> loc) 
            {Lexing.pos_fname="";
             Lexing.pos_lnum=1;
             Lexing.pos_bol=1;
             Lexing.pos_cnum=1} w in*)
        <:expr< $anti:w$ >>
    | _ -> failwith "XML parsing error: problem in antiquotations $...$"

(*
  let list_of_mlast_expr el = 
    List.fold_right 
      (fun x l -> <:expr< [$x$ :: $l$] >>) el <:expr< [] >>

  let list_of_mlast_patt pl = 
    List.fold_right 
      (fun x l -> <:patt< [$x$ :: $l$] >>) pl <:patt< [] >>
*)
  let expr_valorval = function
      EPVstr (v, loc) -> <:expr< $str:v$ >>
    | EPVvar (v, loc) -> <:expr< $lid:v$ >>

  let patt_valorval = function
      EPVstr (v, loc) -> <:patt< $str:v$ >>
    | EPVvar (v, loc) -> <:patt< $lid:v$ >>

  let rec to_expr = function

      EPanyattr (EPVstr (aa,_), v, loc) ->
        let vv = expr_valorval v in
        <:expr< (`$uid:String.capitalize aa$, $vv$) >>

    | EPanyattr (EPVvar (aa,_), v, loc) ->
        let vv = expr_valorval v in
        <:expr< ($lid:aa$, $vv$) >>

    | EPanytag (tag, attribute_list, child_list, loc) ->
        <:expr< `$uid:String.capitalize tag$
          $to_expr_attlist attribute_list$
          $to_expr_taglist child_list$
        >>
        
    | EPpcdata (dt, loc) -> <:expr< `PCData $str:dt$ >>

    | EPwhitespace (dt, loc) -> <:expr< `Whitespace $str:dt$ >>

    | EPanytagvar (v, loc) -> get_expr v
(*        <:expr< $lid:v$ >> *)

    | EPanytagvars (v, loc) -> 
        let s = get_expr v in
        <:expr< `PCData $s$ >>

    | EPcomment (c, loc) -> <:expr< `Comment $str:c$ >>

  and to_expr_taglist = function
      PLEmpty loc -> <:expr< [] >>
    | PLExpr (v, loc) -> get_expr v
    | PLCons (a,l, loc) -> <:expr< [ $to_expr a$ :: $to_expr_taglist l$ ] >>

  and to_expr_attlist = function
      PLEmpty loc -> <:expr< [] >>
    | PLExpr (v, loc) -> get_expr v
    | PLCons (a,l, loc) -> <:expr< [ $to_expr a$ :: $to_expr_attlist l$ ] >>


  let rec to_patt = function

      EPanyattr (EPVstr (a,_), v, loc) -> 
        let vv = patt_valorval v in
        <:patt< ((`$uid:String.capitalize a$), $vv$) >>

    | EPanyattr (EPVvar (a,_), v, loc) ->
        let vv = patt_valorval v in
        <:patt< ($lid:a$, $vv$) >>

    | EPanytag (tag, attribute_list, child_list, loc) ->
        <:patt< `$uid:String.capitalize tag$
          $to_patt_attlist attribute_list$
          $to_patt_taglist child_list$
        >>

    | EPpcdata (dt, loc) -> <:patt< `PCData $str:dt$ >>

    | EPwhitespace (dt, loc) -> <:patt< `Whitespace $str:dt$ >>

    | EPanytagvar (v, loc) -> <:patt< $lid:v$ >>

    | EPanytagvars (v, loc) -> <:patt< `PCData $lid:v$ >>

    | EPcomment (c, loc) -> <:patt< `Comment $str:c$ >>

  and to_patt_taglist = function
      PLEmpty loc -> <:patt< [] >>
    | PLExpr (v, loc) -> <:patt< $lid:v$ >>
    | PLCons (a,l, loc) -> <:patt< [ $to_patt a$ :: $to_patt_taglist l$ ] >>

  and to_patt_attlist = function
      PLEmpty loc -> <:patt< [] >>
    | PLExpr (v, loc) -> <:patt< $lid:v$ >>
    | PLCons (a,l, loc) -> <:patt< [ $to_patt a$ :: $to_patt_attlist l$ ] >>

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
          None -> PLEmpty loc
        | Some l -> l
      in
      let taglist = match child_list with
          None -> PLEmpty loc
        | Some l -> l
      in EPanytag
        (tag,
         attlist, 
         taglist,
         loc)
  | dt = WHITESPACE -> EPwhitespace (dt, loc)
  | dt = DATA -> EPpcdata (dt, loc)
  | c = COMMENT -> EPcomment (c, loc)
  | v = CAMLEXPRXML -> EPanytagvar (v, loc)
  | v = CAMLEXPRXMLS -> EPanytagvars (v, loc)
  ] ];

  exprpatt_any_attribute_list:
  [ [
      v = CAMLEXPRL -> PLExpr (v, loc)
    | a = exprpatt_attr_or_var;
      "=";
      value = exprpatt_value_or_var;
      suite  = OPT exprpatt_any_attribute_list ->
      let suite = match suite with
          None -> PLEmpty loc
        | Some l -> l
      in PLCons (EPanyattr (a,value, loc), suite, loc)
  ] ];

  exprpatt_any_tag_list:
  [ [
      v = CAMLEXPRXMLL;
      OPT WHITESPACE -> PLExpr (v, loc)
    | anytag = exprpatt_any_tag;
      suite  = OPT exprpatt_any_tag_list ->
      let suite = match suite with
          None -> PLEmpty loc
        | Some l -> l
      in PLCons (anytag, suite, loc)
  ] ];

  exprpatt_value_or_var:
  [ [
    v = VALUE -> EPVstr (v, loc)
  | v = CAMLEXPR -> EPVvar (v, loc)
  ] ];

  exprpatt_attr_or_var:
  [ [
    v = ATTR -> EPVstr (v, loc)
  | v = CAMLEXPR -> EPVvar (v, loc)
  ] ];

END;;

let xml_exp s = to_expr (Grammar.Entry.parse exprpatt_xml (Stream.of_string s))
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
