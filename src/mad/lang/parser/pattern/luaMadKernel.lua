local M = { help={}, test={}, _author="MV", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  luaMadKernel

SYNOPSIS
  local LuaMadKernel = require"mad.lang.parser.pattern.luaMadKernel"

DESCRIPTION
  Returns a regex-based grammar. More spesific the grammar of the LuaMad kernel

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- grammar ---------------------------------------------------------------------

M.pattern = [[

chunk <- {|
		s ( ( <stat> ( <sep> s <stat> )* (<sep> s <laststat>)? s <sep>? ) / ( <laststat> s <sep>? )? ) s (!. / '' => error)
	|} -> chunk

	block <- {|
		s ( ( <stat> ( <sep> s <stat> )* (<sep> s <laststat>)? s <sep>? ) / ( <laststat> s <sep>? )? )
	|} -> blockStmt

	stat <- (
		<stmt> / <instant_eval_stmt>
	)
	
	stmt <- ({} (
			<varlist_assign>
		/	<op_assign>
		/	<expr_stmt>
		/	<do_stmt>
		/	<while_stmt>
		/	<repeat_stmt>
		/	<if_stmt>
		/	<for_stmt>
		/	<forin_stmt>
		/	<func_decl>
		/	<locfunc_decl>
		/	<locnamelist>
	)) -> stmt

	varlist_assign <- ({| <varlist> |} s "=" s {| <exp_list> |}) -> varlistAssign

	op_assign <- (
			<var> s <assign_op> s <exp>
	) -> opAssign

	assign_op <- { "+=" / "-=" / "/=" / "*=" }

	loop_body <- <do> s <block> s <end>

	do_stmt <- <loop_body> -> doStmt

	while_stmt <- (
		"while" <idsafe> s <exp> s <loop_body>
		) -> whileStmt

	repeat_stmt <- (
		"repeat" <idsafe> s <block> s "until" <idsafe> s <exp>
		) -> repeatStmt

	if_stmt <- (
		"if" <idsafe> s <exp> s "then" <idsafe> s <block>
		( (s "else" <if_stmt>)
		/ (s "else" <idsafe> s <block> s <end>)
		/ (s <end>))
		) -> ifStmt

	for_stmt <- (
		"for" <idsafe> s <ident> s "=" s <exp> s "," s <exp> ( s "," s <exp> )? s <loop_body>
		) -> forStmt

	forin_stmt <- (
		"for" <idsafe> s {|<name_list>|} s <in> s {|<exp_list>|} s <loop_body>
		) -> forInStmt

	func_decl <- (
		"function" <idsafe> s {| <func_name> |} s <func_body>
		) -> funcDecl

	locfunc_decl <- (
		"local" <idsafe> s "function" <idsafe> s <ident> s <func_body>
		) -> locFuncDecl

	locnamelist <- (
		"local" <idsafe> s {| <name_list> |} ( s "=" s {| <exp_list> |} )?
	) -> locNameList

	laststat <- ({} ( <return_stmt> / <break_stmt> ) ) -> stmt

	return_stmt <- "return" <idsafe> s {| <exp_list>? |} -> returnStmt

	break_stmt <- "break" <idsafe> -> breakStmt

	func_name <- <ident> ( {"."} <ident> )* ( {":"} <ident> )?

	varlist <- <var> ( s "," s <var> )*

	name_list <- <ident> ( s "," s <ident> )*

	exp_list <- <exp> ( s "," s <exp> )*

	expr_stmt <- ({} (<func_call>)) -> exprStmt

	exp <- <infix_exp>

	infix_exp  <- (
		{| <unar_exp> (s <binop> s <unar_exp>)+ |}
	) -> infixExpr / <unar_exp>

	unar_exp <- (
			<unop> s <unar_exp>
	) -> unaryExp / <postfix_exp>

	postfix_exp <- ( <nil_exp> / <literal> / "..." / <function> / <lambda_decl> / <prefix_exp> / <tableconstructor> )

	var <- (
			( <ident> / "(" s <exp> s ")"  <varsuffix> ) (s <varsuffix>)*
	)

	prefix_exp <- ( 
			{|<varorexp>|}  {|<identthenargs>*|}
	) -> prefixExp

	func_call <- ( 
			{|<varorexp>|}  {|<identthenargs>+|} 
	) -> funcCall

	varorexp <- (
			<var> / ( "(" s <exp> s ")" )
	)

	identthenargs <- (
			( {":"} s <ident> s )? <args>
	)

	varsuffix <- (
			(<identthenargs> s)*  ( {"["} s <exp> s "]" / {"."}  <ident> )
	)

	args <-	(
			"(" s {| <exp_list>? |} s ")" / <tableconstructor> / (<string> -> literal) 
	)

	function <- (
			"function" <idsafe> s <func_body>
	) -> funcExpr

	lambda_decl <- (
		"\" {| <parlist>? |} s ( ({| <exp> |}) / ( "(" s {| <exp_list> |} s ")" ))
	) -> lambdaDecl

	func_body <- (
			"(" s {| <parlist>? |} s ")" s <block> s <end>
	)

	parlist <- (<name_list> (s "," s {"..."})? / {"..."})

	tableconstructor <- (
			"{" s {| <fieldlist>? |} s "}"
	) -> tableConstr

	fieldlist <- (<field> ( s <fieldsep> s <field> )* s <fieldsep>?)

	field <- (
			( {"["} s <exp> s "]" s {"="} s <exp> ) / ( <ident> s {"="} s <exp> ) / <exp>
	)

	fieldsep <- "," / ";"

	binop <- ({ "+" / "-" / "*" / "/" / "^" / "%" / ".." / 
		 "<" / "<=" / ">" / ">=" / "==" / "~=" / 
		 (( "and" / "or" ) <idsafe>) })

	unop <- { "-" / ("not" <idsafe>) / "#" }
]]

return M
