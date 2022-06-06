(* semantic.ml *)

open Absyn

let rec check_exp (loc, exp) vtable ftable =
  match exp with
  | IntExp x -> Int
  | VarExp v ->
   ( match Symbol.look v vtable with
    | Some t -> t
    | None -> Error.error loc "undefined variable %s" (Symbol.name v)
   )
  | LetExp (v, init, body) ->
     let t_init = check_exp init vtable ftable in
     let vtable' = Symbol.enter v t_init vtable in
     check_exp body vtable' ftable
  | _ -> Error.fatal "unimplemented"

let get_typeid (t, id) =
    (t, id)

let rec check_typeids typeids =
  match typeids with
  | [] -> Error.fatal "parameter list cannot be null"
  | [typeid] ->
     let (t, (_loc, x)) = get_typeid typeid in
     Symbol.enter x t Symbol.empty
  | typeid :: typeids ->
     let (t, (loc, x)) = get_typeid typeid in
     let vtable = check_typeids typeids in
     match Symbol.look x vtable with
     | None -> Symbol.enter x t vtable
     | Some _ -> Error.error loc "parameter already defined"

let get_types typeids =
   List.map fst typeids

let get_fun (typeid, params, body) =
   let (t0, (_, f)) = get_typeid typeid in
   let tparams = get_types params in
   (f, (tparams, t0))

let check_fun (loc, (typeid, typeids, exp)) ftable =
   let (t0, (_, f)) = get_typeid typeid in
   let vtable = check_typeids typeids in
   let t1 = check_exp exp vtable ftable in
   if t0 <> t1 then
      Error.error (Location.loc exp) "type mismatch in function body"

let check_funs funs ftable =
   List.iter (fun f -> check_fun f ftable) funs

let rec get_funs funs =
  match funs with
  | [] -> Error.fatal "no funtion is not allowed"
  | [(_, fundec)] ->
     let (f, t) = get_fun fundec in
     Symbol.enter f t Symbol.empty
  | (loc, fundec) :: rest ->
     let (f, t) = get_fun fundec in
     let ftable = get_funs rest in
     match Symbol.look f ftable with
     | Some _ ->
        Error.error loc "function %s defined more than once" (Symbol.name f)
     | None ->
        Symbol.enter f t ftable

let check_program (loc, Program funs) =
  let ftable = get_funs funs in
  check_funs funs ftable;
  match Symbol.look (Symbol.symbol "main") ftable with
  | Some ([Int], Int) -> ()
  | Some _ -> Error.error loc "wrong type for main function"
  | None -> Error.error loc "missing main function"

let semantic ast =
   check_program ast
