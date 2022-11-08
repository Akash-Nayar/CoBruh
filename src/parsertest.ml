open Ast
open Parser

let deflate token = 
  let q = Queue.create () in
  fun lexbuf -> 
    if not (Queue.is_empty q) then Queue.pop q else   
      match token lexbuf with 
        | [   ] -> EOF 
        | [tok] -> tok
        | hd::t -> List.iter (fun tok -> Queue.add tok q) t ; hd 

let _ =
  let lexbuf = Lexing.from_channel stdin in
  let program = Parser.program (deflate Scanner.token) lexbuf in
  Printf.fprintf stdout "%s\n" (string_of_program program);
