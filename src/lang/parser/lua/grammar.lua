local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  grammar

SYNOPSIS
  local grammar = require"lang.parser.lua.grammar".grammar

DESCRIPTION
  Returns the regex-based grammar of Lua.

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- grammar ---------------------------------------------------------------------

M.grammar = [[

chunk <- "" => setup {| 
		s ( ( <stat> ( <sep> s <stat> )* (<sep> s <laststat>)? s <sep>? ) / ( <laststat> s <sep>? )? ) s (!. / '' => error)
	|} -> chunk

	block <- {|
		s ( ( <stat> ( <sep> s <stat> )* (<sep> s <laststat>)? s <sep>? ) / ( <laststat> s <sep>? )? )
	|} -> blockStmt
	
	close		<- (']' =eq ']') / {(!']' .)*}

	newline <- %nl -> newLine

	lcomment	<- ({} (!<newline> %s)* "--" {(!<newline> .)*} <newline>) -> lcomm
	bcomment	<- ({} ('--[' {:eq: '='* :} '[' <close>)) -> bcomm
	comment		<- <bcomment> / <lcomment>
	idsafe		<- !(%alnum / "_")
	s					<- (<comment> / %s)*
	S					<- (<comment> / %s)+
	hs				<- (!<newline> %s)*
	HS				<- (!<newline> %s)+
	digits		<- %digit (%digit / (&('_' %digit) '_') %digit)*
	word			<- (%alpha / "_") (%alnum / "_")*

	keyword	<- (
		"local" / "function" / 
		/ "nil" / "true" / "false" / "return" / "end"
		/ "break" / "not"
		/ "while" / "do" / "for" / "in" / "of" / "and" / "or"
		/ "if" / "elseif" / "else" / "then"
		/ "repeat" / "until"
	) <idsafe>

	sep <- <bcomment>? (<newline> / ";" / &"}" / <lcomment>) / %s <sep>?

	astring <- "'" { (!"'" .)* } "'"
	qstring <- '"' { (!'"' .)* } '"'
	lstring <- ('[' {:eq: '='* :} '[' <close>)

	string	<- (
		 <qstring> / <astring> / <lstring>
	) -> string

	hexnum <- "-"? "0x" %xdigit+

	decexp <- ("e"/"E") "-"? <digits>

	decimal <- "-"? <digits> ("." <digits> <decexp>? / <decexp>)

	integer <- "-"? <digits>

	number	<- {~
		 <hexnum> / <decimal> / <integer>
	~} -> tonumber

	nil_exp <- "nil" <idsafe> -> nilExpr

	bool_exp <- ( {"true" / "false"} ) <idsafe> -> boolean

	 in		<- "in"	<idsafe>
	 end	<- "end" <idsafe>
	 do		<- "do"	<idsafe>

	literal <- ( <number> / <string> / <bool_exp> ) -> literal

	ident <- (
		!<keyword> { <word> }
		) -> identifier

	stat <- (
		<stmt>
	)
	
	stmt <- ({} (
			<varlist_assign>
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

	postfix_exp <- ( <nil_exp> / <literal> / ("..." -> identifier) / <function> / <prefix_exp> / <tableconstructor> )

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
			"(" s {| <exp_list>? |} s ")" / {|<tableconstructor>|} / ({|<string> -> literal|}) 
	)

	function <- (
			"function" <idsafe> s <func_body>
	) -> funcExpr

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
