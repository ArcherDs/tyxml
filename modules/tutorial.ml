(* Ocsigen Tutorial *)
(* See http://www.ocsigen.org for a more detailed version *)

open XHTML.M
open Ocsigen


(* ------------------------------------------------------------------ *)
(* To create a web page without parameter: *)
let coucou1 = 
  register_new_url 
    ~path:["coucou1"]
    ~get_params:unit
    (fun _ () () ->
    << <html>
         <head><title></title></head>
         <body><h1>Coucou</h1></body>
       </html> >>)

let coucou = 
  register_new_url 
    ~path:["coucou"]
    ~get_params:unit
    (fun _ () () ->
      (html
	 (head (title (pcdata "")) [])
	 (body [h1 [pcdata "Hallo"]])))

(* Pages can have side effects: *)
let compt = 
  let next =
    let c = ref 0 in
      (fun () -> c := !c + 1; !c)
  in
  register_new_url 
    ~path:["compt"]
    ~get_params:unit
    (fun _ () () -> 
      (html
       (head (title (pcdata "counter")) [])
       (body [p [pcdata (string_of_int (next ()))]])))

(* As usual in OCaml, you can forget labels when the application is total: *)
let hello = 
  register_new_url 
    ["dir";"hello"]  (* the url dir/hello *)
    unit
    (fun _ () () ->
    << <html> 
         <head><title>hello</title></head>
         <body><h1>hello</h1></body>
       </html> >>)


(* the url rep/ is not equivalent to rep *)
let default = register_new_url ["rep";""] unit
  (fun _ () () ->
  << <html>
       <head><title></title></head>
       <body>
         <p>default page. rep is redirected to rep/</p>
       </body>
     </html> >>)


(* ------------------------------------------------------------------ *)
let writeparams _ (entier, (chaine, chaine2)) () = 
<< <html>
    <head><title></title></head>
    <body>
    <p>
      You sent to me: 
      <strong>$str:string_of_int entier$</strong> and
      <strong>$str:chaine$</strong> and
      <strong>$str:chaine2$</strong>
    </p>
    </body>
  </html> >>

(* you can register twice the same url, with different parameters names *)
let coucou_params = register_new_url 
    ~path:["coucou"]
    ~get_params:(int "entier" ** (string "chaine" ** string "chaine2"))
    writeparams
(* If you register twice exactly the same URL, the server won't start *)


(* ------------------------------------------------------------------ *)
(* A web page without parameter which has access to the user-agent 
   and which answers to any url of the form uaprefix/*
   Warning: for server params, use *** instead of **
*)
let uaprefix = 
  register_new_url 
    ~path:["uaprefix"]
    ~get_params:(suffix (string "s"))
    ~prefix:true
    (fun h (suff, s) () -> 
       << <html>
            <head><title></title></head>
            <body>
              <p>
	      The suffix of the url is <strong>$str:suff$</strong>
              and your user-agent is <strong>$str:h.user_agent$</strong>
              and your IP is <strong>$str:Unix.string_of_inet_addr h.ip$
                             </strong>
              and s is <strong>$str:s$</strong>
              </p>
            </body>
          </html> >>)

let iprefix = 
  register_new_url 
    ~path:["iprefix"] 
    ~prefix:true 
    ~get_params:(suffix (int "i"))
    (fun h (suff, i) () -> 
<< <html>
     <head><title></title></head>
     <body><p>
       The suffix of the url is <strong>$str:suff$</strong> 
       and i is <strong>$str:string_of_int i$</strong>
     </p></body>
   </html> >>)


(* ------------------------------------------------------------------ *)
(* To create a link to a registered url, use the a function: *)

let links = register_new_url ["rep";"links"] unit
    (fun h () () ->
      (html
	 (head (title (pcdata "")) [])
	 (body 
	    [p
	       [a coucou h.current_url [pcdata "coucou"] (); br ();
		a hello h.current_url [pcdata "hello"] (); br ();
		a default h.current_url 
		  [pcdata "default page of the directory"] (); br ();
                a uaprefix h.current_url 
		  [pcdata "uaprefix"] ("suff","toto"); br ();
                a coucou_params h.current_url 
		  [pcdata "coucou_params"] (42,("ciao","hallo")); br ();
                a
	          (new_external_url
		     ~path:["http://fr.wikipedia.org";"wiki"]
		     ~prefix:true
		     ~get_params:suffix_only
		     ~post_params:unit ()) 
                  h.current_url
	          [pcdata "ocaml on wikipedia"]
                  "OCaml"]])))
    
(* Note that to create a link we need to know the current url, because:
   the link from toto/titi to toto/tata is "tata" and not "toto/tata"
*)



(* Note new_external_url to create a link on external url *)
(* If you want to put a link towards a page that is not already defined,
   you can break register_new_url into new_url and register_url.
   Do not forget to register the url!!!
 *)

let linkrec = new_url ["linkrec"] unit ()

let _ = register_url linkrec 
    (fun h () () -> 
      << <html>
          <head><title></title></head>
          <body><p>$a linkrec h.current_url <:xmllist< click >> ()$</p></body>
         </html> >>)

(* If some url are not registered, the server will not start:
let essai = 
  new_url 
   ~path:["essai"]
   ~server_params:no_server_param
   ~get_params:no_get_param
   ()
*)

(* ------------------------------------------------------------------ *)
(* To create a form, call the function form with the name of a registered
   url and a function that takes the names of the parameters and
   build the formular
*)
let create_form = 
  (fun (entier,(chaine,chaine2)) ->
    <:xmllist< <p>Write an int: $int_input entier$ <br/>
    Write a string: $string_input chaine$ <br/>
    Write a string: $string_input chaine2$ <br/>
    $submit_input "Click"$</p>
    >>)

let form = register_new_url ["form"] unit
  (fun h () () -> 
     let f = get_form coucou_params h.current_url create_form in
     << <html>
          <head><title></title></head>
          <body> $f$ </body>
        </html> >>)


(* ------------------------------------------------------------------ *)
(* By default parameters of a web page are in the URL (GET parameters).
   A web page may expect parameters from the http header (POST parameters,
   that is parameters which are not in the URL).
   Use this if you don't want the user to be able to bookmark
   the URL with parameters, for example if you want to post some
   data that will change the state of the server (database, etc).
   When you register an URL with POST parameters, you must register
   before an url (fallback) without these parameters (for example that will
   answer if the page is reloaded without the hidden parameters, or
   bookmarked).
 *)
let no_post_param_url = 
  register_new_url 
    ~path:["post"]
    ~get_params:unit
    (fun _ () () ->
      (html
	 (head (title (pcdata "")) [])
	 (body [h1 [pcdata 
		      "Version of the page without POST parameters"]])))
    
let my_url_with_post_params = register_new_post_url
    ~fallback:no_post_param_url
    ~post_params:(string "value")
    (fun _ () value -> 
      (html
	 (head (title (pcdata "")) [])
	 (body [h1 [pcdata value]])))

(* You can mix get and post parameters *)
let getno_post_param_url = 
  register_new_url 
    ~path:["post2"]
    ~get_params:(int "i")
    (fun _ i () -> 
      (html
	 (head (title (pcdata "")) [])
	 (body [p [pcdata "No POST parameter, i:";
		   em [pcdata (string_of_int i)]]])))

let my_url_with_get_and_post = register_new_post_url 
  ~fallback:getno_post_param_url
  ~post_params:(string "value")
  (fun _ i value -> 
      (html
	 (head (title (pcdata "")) [])
	 (body [p [pcdata "Value: ";
		   em [pcdata value];
		   pcdata ", i: ";
		   em [pcdata (string_of_int i)]]])))

(* ------------------------------------------------------------------ *)
(* To create a POST form, use the post_form function,
   possibly applied to GET parameters (if any)
*)

let form2 = register_new_url ["form2"] unit
  (fun h () () -> 
     let f = 
       (post_form my_url_with_post_params h.current_url
	  (fun chaine -> 
	    [p [pcdata "Write a string: ";
		string_input chaine]]) ()) in
     (html
	(head (title (pcdata "--")) [])
	(body [f])))

let form3 = register_new_url ["form3"] unit
  (fun h () () ->
     let f  = 
       (post_form my_url_with_get_and_post h.current_url
	  (fun chaine -> 
	    <:xmllist< <p> Write a string: $string_input chaine$ </p> >>)
	  222) in
       << <html><head><title></title></head><body>$f$</body></html> >>)

let form4 = register_new_url ["form4"] unit
  (fun h () () ->
     let f  = 
       (post_form
	  (new_external_url 
	     ~path:["http://www.petitspois.com"]
	     ~get_params:(int "i")
	     ~post_params:(string "chaine") ()) h.current_url
	  (fun chaine -> 
	    <:xmllist< <p> Write a string: $string_input chaine$ </p> >>)
	  222) in
       << <html><body>$f$</body></html> >>)
       


(* ------------------------------------------------------------------ *)
(* URL with state:
   You can define new urls that differs from public url only by a (hidden)
   parameter (internal state).
   To do that, use new_state_url and new_post_state_url.
   Actually the text of the URL need to be exactly the same as a public
   url, so that it doesn't fail if you bookmark the page.
   That's why new_state_url and new_post_state_url take a public
   URL as parameter (called fallback).
   The session URL will have the same GET parameters but may have
   different POST parameters.
   This session URL will be differenciated from the public one by an internal
   (hidden) parameter.

   This parameter is an hidden post
   parameter if possible... (but in the case of a GET form, it is not 
   possible :-( and for a link it is difficult to do...).

   ** I am not sure whether we should allow them in global table or not
   or only in session tables because of the problem of GET parameters ** 

   Solutions (?) : 
    - interdire les url avec �tat en dehors des sessions ?
    - trouver un moyen d'utiliser la redirection pour changer l'url au vol ?
    - ... ?
 *)

let ustate = new_url ["state"] unit ()

let ustate2 = new_state_url ~fallback:ustate

let _ = 
  let c = ref 0 in
  let page h () () = 
    let l3 = post_form ustate2 h.current_url 
	(fun _ -> [p [submit_input "incr i (post)"]]) () in
    let l4 = get_form ustate2 h.current_url 
	(fun _ -> [p [submit_input "incr i (get)"]]) in
    (html
       (head (title (pcdata "")) [])
       (body [p [pcdata "i is equal to ";
		 pcdata (string_of_int !c); br ();
		 a ustate h.current_url [pcdata "reload"] (); br ();
		 a ustate2 h.current_url [pcdata "incr i"] ()];
              l3;
	      l4]))
  in
    register_url ustate page;
    register_url ustate2 (fun h () () -> c := !c + 1; page h () ())


(* ------------------------------------------------------------------ *)
(* You can replace some public url by an url valid only for one session.
   To create this value, use register_url_for_session or
   register_post_url_for_session

   Use this for example if you want two versions of each page,
   one public, one for connected users

   To close a session, use close_session ()
*)
let public_session_without_post_params = 
  new_url ~path:["session"] ~get_params:unit ()

let public_session_with_post_params = 
  new_post_url 
    ~fallback:public_session_without_post_params
    ~post_params:(string "login")

let accueil h () () = 
  let f = post_form public_session_with_post_params h.current_url
    (fun login -> 
	 [p [pcdata "login: ";
	     string_input login]]) () in
  (html
     (head (title (pcdata "")) [])
     (body [f]))


let _ = register_url
  ~url:public_session_without_post_params
  accueil

let rec launch_session h () login =
  let close = register_new_state_url_for_session
    ~fallback:public_session_without_post_params 
    (fun h () () -> close_session (); accueil h () ())
  in
  let new_main_page h () () =
    (html
       (head (title (pcdata "")) [])
       (body [p [pcdata "Welcome ";
		 pcdata login; 
		 pcdata "!"; br ();
		 a coucou h.current_url [pcdata "coucou"] (); br ();
		 a hello h.current_url [pcdata "hello"] (); br ();
		 a links h.current_url [pcdata "links"] (); br ();
		 a close h.current_url [pcdata "close session"] ()]]))
  in
  register_url_for_session 
    ~url:public_session_without_post_params 
    (* url is any public url already registered *)
    new_main_page;
  register_url_for_session 
    ~url:coucou
    (fun _ () () ->
      (html
	 (head (title (pcdata "")) [])
	 (body [p [pcdata "Coucou ";
		   pcdata login;
		   pcdata "!"]])));
  register_url_for_session 
    hello
    (fun _ () () ->
      (html
	 (head (title (pcdata "")) [])
	 (body [p [pcdata "Ciao ";
		   pcdata login;
		   pcdata "!"]])));
  new_main_page h () ()
    
let _ =
  register_url
    ~url:public_session_with_post_params
    launch_session

(* Registering for session during initialisation is forbidden:
let _ = register_url_for_session
    ~url:coucou1 
    << <html>
         <head><title></title></head>
         <body><h1>humhum</h1></body>
       </html> >>
*)


(* ------------------------------------------------------------------ *)
(* You can register url with states in session tables.
   Use this if you want a link or a form which depends precisely on an
   instance of the web page, for example to buy something on an internet shop.
   UPDATE: Actually it is not a good example, because what we want in a shop
   is the same shoping basket for all pages. 
   SEE calc example instead.
*)
let shop_without_post_params =
  new_url
   ~path:["shop"]
   ~get_params:unit
    ()

let shop_with_post_params =
  new_post_url
    ~fallback:shop_without_post_params
    ~post_params:(string "article")

let write_shop shop url =
  (post_form shop url
     (fun article -> 
	let sb = string_input article in
	  <:xmllist< <p> What do you want to buy? $sb$ </p> >>) ())

let shop_public_main_page h () () =
  let f = write_shop shop_with_post_params h.current_url in
    << <html><body>$f$</body></html> >>

let _ = 
  register_url shop_without_post_params shop_public_main_page
    

let write_shopping_basket shopping_basket =
  let rec aux = function
      [] -> [<< <br/> >>]
    | a::l -> let fol = aux l in <:xmllist< $str:a$ <br/> $list:fol$ >>
  in
  let ffol = aux shopping_basket in
    <:xmllist< Your shopping basket: <br/> $list:ffol$ >>

let rec page_for_shopping_basket url shopping_basket =
  let local_shop_with_post_params = 
    new_post_state_url
      ~fallback:shop_without_post_params
      ~post_params:(string "article")
  and local_pay = new_state_url ~fallback:shop_without_post_params
  in
    register_url_for_session
      ~url:local_shop_with_post_params
      (fun h () article -> 
		 page_for_shopping_basket 
		   h.current_url (article::shopping_basket));
    register_url_for_session
      local_pay
      (fun h () () ->
	   << <html><body>
	        <p>You are going to pay: 
                  $list:write_shopping_basket shopping_basket$ </p>
              </body></html> >>);
      << <html>
           <body> 
             <div>$list:write_shopping_basket shopping_basket$</div>
             $write_shop local_shop_with_post_params url$ 
             <p>$a local_pay url <:xmllist< pay >> ()$</p>
           </body>
         </html> >>

let _ = register_url
  ~url:shop_with_post_params
  (fun h () article -> page_for_shopping_basket h.current_url [article])


(* Queinnec example: *)

let calc = 
  new_url
    ~path:["calc"]
    ~get_params:unit
    ()

let calc_post = 
  new_post_url 
    ~fallback:calc
    ~post_params:(int "i")

let _ = 
  let create_form is = 
    (fun entier ->
      let ib = int_input entier in
      let b = submit_input "Sum" in
      <:xmllist< <p> $str:is$ + $ib$ <br/>
      $b$ </p>
      >>)
  in
  register_url
    ~url:calc_post
    (fun h () i ->
      let is = string_of_int i in
      let calc_result = register_new_post_state_url_for_session
	  ~fallback:calc
	  ~post_params:(int "j")
	  (fun h () j -> 
	    let js = string_of_int j in
	    let ijs = string_of_int (i+j) in
	    << <html> 
                 <body><p> 
                   $str:is$ + $str:js$ = $str:ijs$ </p>
                 </body></html> >>)
      in
      let f = 
	post_form calc_result h.current_url (create_form is) () in
      << <html><body>$f$</body></html> >>)
    
let _ =   
  let create_form = 
    (fun entier ->
      <:xmllist< <p> Write a number: $int_input entier$ <br/>
      $submit_input "Send"$ </p>
      >>)
  in
  register_url
    calc
    (fun h () () ->
      let f = post_form calc_post h.current_url create_form () in
      << <html><body>$f$</body></html> >>)
      

(* Actions: *)
(* Actions are like url but they do not generate any page.
   For ex, when you have the same form (or link) on several pages 
   (for ex a connect form),
   instead of making a version with post params of all these pages,
   you can use actions.
   Create and register an action with new_actionurl, register_actionurl,
     register_new_actionurl, register_actionurl_for_session,
     register_state_actionurl_for_session
   Make a form or a link to an action with action_form or action_a.
   By default, they print the page again after having done the action.
   But you can give the optional boolean parameter reload to action_form
   or action link to prevent reloading the page.
*)
let action_session = 
   new_url ~path:["action"] ~get_params:unit ()

let connect_action = new_actionurl ~post_params:(string "login")

let accueil_action h () () = 
  let f = action_form connect_action h
      (fun login -> 
	[p [pcdata "login: "; 
	    string_input login]]) in
  html
    (head (title (pcdata "")) [])
    (body [f])


let _ = register_url
  ~url:action_session
  accueil_action

let rec launch_session login =
  let deconnect_action = 
   register_new_actionurl unit (fun _ () -> close_session ()) in
  let deconnect_box h s = action_a deconnect_action h s in
  let new_main_page h () () =
    html
      (head (title (pcdata "")) [])
      (body [p [pcdata "Welcome ";
		pcdata login; br ();
		a coucou h.current_url [pcdata "coucou"] (); br ();
		a hello h.current_url [pcdata "hello"] (); br ();
		a links h.current_url [pcdata "links"] (); br ()];
	     deconnect_box h [pcdata "Close session"]])
  in
  register_url_for_session ~url:action_session new_main_page;
  register_url_for_session coucou
   (fun _ () () ->
     (html
       (head (title (pcdata "")) [])
       (body [p [pcdata "Coucou ";
		 pcdata login;
		 pcdata "!"]])));
  register_url_for_session hello 
   (fun _ () () ->
     (html
       (head (title (pcdata "")) [])
       (body [p [pcdata "Ciao ";
		 pcdata login;
		 pcdata "!"]])))
    
let _ = register_actionurl
    ~actionurl:connect_action
    ~action:(fun _ login -> launch_session login)


(* ------------------------------------------------------------------ *)
(* Advanced types *)
(* You can use your own types *)
type mysum = A | B
let mysum_of_string = function
    "A" -> A
  | "B" -> B
  | _ -> raise (Failure "mysum_of_string")
let string_of_mysum = function
    A -> "A"
  | B -> "B"

let mytype = register_new_url 
  ["mytype"]
  (user_type mysum_of_string string_of_mysum "valeur")
  (fun _ x () -> let v = string_of_mysum x in
    (html
       (head (title (pcdata "")) [])
       (body [p [pcdata v]])))


(* lists *)
let coucou_list = register_new_url 
    ~path:["coucou"]
    ~get_params:(list "a" (int "entier"))
  (fun _ l () ->
    let ll = 
      List.map (fun i -> << <strong>$str:string_of_int i$</strong> >>) l in
  << <html>
       <head><title></title></head>
       <body>
       <p>
         You sent: 
         $list:ll$
       </p>
       </body>
     </html> >>)

(* http://localhost:8080/coucou?a=2&a.entier[0]=6&a.entier[1]=7 *)

(* Advanced forms *)
(* Form with list: *)
let create_listform f =
  f.it (fun intname v ->
    <:xmllist< <p>Write the value for $str:v$: $int_input intname$ </p> >>)
    ["one";"two";"three";"four"]
    <:xmllist< <p>$submit_input "Click"$</p> >>

let listform = register_new_url ["listform"] unit
  (fun h () () -> 
     let f = get_form coucou_list h.current_url create_listform in
     << <html>
          <head><title></title></head>
          <body> $f$ </body>
        </html> >>)

(* Form for URL with suffix: *)
let create_suffixform (suff,i) =
    <:xmllist< <p>Write the suffix: $string_input suff$ <br/>
      Write an int: $int_input i$ <br/>
      $submit_input "Click"$</p> >>

let suffixform = register_new_url ["suffixform"] unit
  (fun h () () -> 
     let f = get_form iprefix h.current_url create_suffixform in
     << <html>
          <head><title></title></head>
          <body> $f$ </body>
        </html> >>)



(* Main page for this example *)
let main = new_url [] unit ()

let _ = register_url main
  (fun h () () ->
    let url = h.current_url in
    (* Do not register a page after initialisation.
       This will cause an error:
       let coucou6 = 
       new_url 
	~path:["coucou6"]
        ~server_params:no_server_param
	~get_params:no_get_param 
        ()
       in *)
    (* This will be ignored: register_url coucou1 << <html></html> >>; *)
     << 
       <html> 
       <!-- This is a comment! -->
       <head>
	 $css_link (make_uri static_dir url "style.css")$
	 <title>Ocsigen Tutorial</title>
       </head>
       <body>
       <h1>Ocsigen</h1>
       <h2>Examples</h2>
       <h3>Simple pages</h3>
       <p>
       Une page simple : $a coucou url <:xmllist< coucou >> ()$ <br/>
       Une page avec un compteur : $a compt url <:xmllist< compt >> ()$ <br/> 
       Une page simple dans un r�pertoire : 
	   $a hello url <:xmllist< dir/hello >> ()$ <br/>
       Default page of a directory:
           $a default url <:xmllist< rep/ >> ()$</p>
       <h3>Parameters</h3>
       <p>
       Une page avec param�tres GET : 
	   $a coucou_params url <:xmllist< coucou avec params >> (45,("hello","krokodile"))$ (que se passe-t-il si le premier param�tre n'est pas un entier ?)<br/> 
       Une page avec URL "pr�fixe" qui r�cup�re l'IP et l'user-agent : 
	   $a uaprefix url <:xmllist< uaprefix >> ("suf", "toto")$ <br/> 
       Une page URL "pr�fixe" avec des param�tres GET : 
	   $a iprefix url <:xmllist< iprefix >> ("popo", 333)$ <br/> 
       Une page qui r�cup�re un param�tre d'un type utilisateur : 
	     $a mytype url <:xmllist< mytype >> A$ </p>
       <h3>Links and Formulars</h3>
       <p>
       Une page avec des liens : $a links url <:xmllist< links >>  ()$ <br/> 
       Une page avec un lien vers elle-m�me : 
	     $a linkrec url <:xmllist< linkrec >> ()$ <br/>
       The $a main url <:xmllist< default page >> ()$ 
	   of this directory (myself) <br/>
       Une page avec un formulaire GET qui pointe vers la page coucou avec params : 
	     $a form url <:xmllist< form >> ()$ <br/> 
       Un formulaire POST qui pointe vers la page "post" : 
	     $a form2 url <:xmllist< form2 >> ()$ <br/> 
       La page "post" quand elle ne re�oit pas de param�tres POST : 
	     $a no_post_param_url url <:xmllist< post sans post_params >> ()$ <br/> 
       Un formulaire POST qui pointe vers une URL avec param�tres GET : 
	     $a form3 url <:xmllist< form3 >> ()$ <br/> 
       Un formulaire POST vers une page externe : 
	     $a form4 url <:xmllist< form4 >> ()$ </p> 
       <h3>Sessions</h3>
       <p>
       URL avec �tat : 
	     $a ustate url <:xmllist< state >> ()$ (probl�me des param�tres GET bookmark�s...) <br/> 
       Une session bas�e sur les cookies : 
	     $a public_session_without_post_params url <:xmllist< session >> ()$ <br/> 
       Une session avec des actions : 
	     $a action_session url <:xmllist< actions >> ()$ <br/>
       Une session avec "url de sessions" : 
	     $a calc url <:xmllist< calc >> ()$
       - (ancienne version : $a shop_without_post_params url <:xmllist< shop >> ()$)
       </p>
       </body>
     </html> >>)


(* WARNING! As we don't use threads, 
   the following page will stop the server 5 seconds!!!
let _ = 
  register_new_url 
    ~path:["loooooooooong"]
    ~server_params:unit
    ~get_params:no_get_param
    (fun () -> 
               Unix.sleep 5;
	       << <html><body><p>Ok now, you can read the page.</p></body></html> >>)

 *)

