open CoBruh

type action = Parse | Semantics | Ir | Compile

let _ =
  let deflate token = 
    let q = Queue.create () in
    fun lexbuf -> 
      if not (Queue.is_empty q) then Queue.pop q else   
        match token lexbuf with 
          | [] -> Parser.EOF 
          | [tok] -> tok
          | hd::tl -> List.iter (fun tok -> Queue.add tok q) tl; hd 
  in
  let action = ref Compile in
  let set_action a () = action := a in
  let speclist = [
    ("-p", Arg.Unit (set_action Parse), "Print AST");
    ("-s", Arg.Unit (set_action Semantics), "Print semantics check");
    ("-l", Arg.Unit (set_action Ir), "Print LLVM IR");
    ("-c", Arg.Unit (set_action Compile), "Check and print LLVM IR (default)");
  ] in  
  let usage_msg = "usage: ./cobruh [-a|-s|-l|-c] [file.bruh]" in
  let in_channel = ref stdin in
  let out_channel = ref stdout in
  Arg.parse speclist (fun filename -> in_channel := open_in filename) usage_msg;
  
  let lexbuf = Lexing.from_channel !in_channel in
  match !action with
    Parse -> 
      let ast = try Some (Parser.program (deflate Scanner.token) lexbuf) with Failure err -> Printf.fprintf !out_channel "\nError: %s\n" err; None in
      (
        match ast with
            Some s -> Printf.fprintf !out_channel "\n%s\n" (Ast.string_of_program s)
          | None -> ()
      )
  | Semantics -> 
      let ast = Parser.program (deflate Scanner.token) lexbuf in
      Printf.fprintf !out_channel "\n%s\n" (Ast.string_of_program ast);
      let sast = try Some (Semant.check ast) with Failure err -> Printf.fprintf !out_channel "\nError: %s" err; None in
      Printf.fprintf !out_channel "\n%s\n" (
        match sast with
            Some _ -> "Passed semantics check"
          | None -> "Failed semantics check"
      )
  | Ir ->
      let ast = Parser.program (deflate Scanner.token) lexbuf in
      let sast = Semant.check ast in
      let ir = Irgen.translate sast in
      Printf.fprintf !out_channel "\n%s\n" (Llvm.string_of_llmodule ir)
  | Compile ->
      let ast = Parser.program (deflate Scanner.token) lexbuf in
      let sast = Semant.check ast in
      let ir = Irgen.translate sast in
      Llvm_analysis.assert_valid_module ir;
      Printf.fprintf !out_channel "\n%s\n" (Llvm.string_of_llmodule ir)
