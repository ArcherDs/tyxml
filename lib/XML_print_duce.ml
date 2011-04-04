(* Ocsigen
 * Copyright (C) 2011 Jaap Boender
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

(**
   Pretty printer for XHTML with Ocamlduce.
   Handles browser specificities properly.

   @author Jaap Boender
*)

module Make(I: sig val emptytags : string list end) = struct

  let print_list
      ~output
      ?(encode = XML_print.encode_unsafe_char)
      (v: Ocamlduce.Load.anyxml list) : unit =

    let open_markup tag attrs =
      output ("<" ^ tag);
      List.iter
	(fun (n, v) ->
	  output " "; output n; output "=\""; output (encode v); output "\"")
	attrs
    in
    List.iter
      (Ocamlduce.Print.serialize
	 ~start_elem:(fun tag attrs -> open_markup tag attrs; output ">")
	 ~end_elem:(fun tag -> output ("</" ^ tag ^ ">"))
	 ~empty_elem:(fun tag attrs ->
	   if List.mem tag I.emptytags then
	     (open_markup tag attrs; output " />")
	   else
	     (open_markup tag attrs; output ("></" ^ tag ^ ">")))
	 ~text:(fun v -> output (encode v)))
      v

end

module MakeTypedRaw(TypedXML : XML_sigs_duce.TypedXML) = struct

  module P = Make(TypedXML.Info)

  type elt
  type doc

  let print_list ~output ?(encode = XML_print.encode_unsafe_char) elts =
    P.print_list ~output ~encode elts

  let print ~(output: string  -> unit) ?(encode = XML_print.encode_unsafe_char) ?(advert = "")
      doc =
    output TypedXML.Info.doctype;
    if advert <> "" then output ("<!-- " ^ advert ^ " -->\n");
    P.print_list ~output ~encode [doc]

end

let print ~output ?(encode = XML_print.encode_unsafe_char) elt =
  let module P = Make(struct let emptytags = [] end) in
  P.print_list ~output ~encode [elt]
