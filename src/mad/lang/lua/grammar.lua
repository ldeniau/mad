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

	chunk <- ("" => setup {| 
		( ( <stat> <sep>? )* (<laststat>)? <sep>? ) s (!. / '' => error)
	|}) -> chunk

	block <- ({|
		( ( <stat> <sep>? )* (<laststat>)? <sep>? )
	|}) -> blockStmt
	
	stat <- ({} (
			( ( ";" ) )
		/	( ( {| <varlist> |} "=" {| <exp_list> |} ) -> varlistAssign )
		/	( ( {} <func_call> ) -> exprStmt	)
		/	( ( <loop_body> ) -> doStmt )
		/	( (	<while> <exp> <loop_body>	) -> whileStmt)
		/	( (	<repeat> <block> <until> <exp> ) -> repeatStmt )
		/ ( ( <if> <rest_of_if> ) )
		/	( (	<for> <ident> "=" <exp> "," <exp> ( "," <exp> )? <loop_body> ) -> forStmt )
		/	( (	<for> {|<name_list>|} <in> {|<exp_list>|} <loop_body>	) -> forInStmt )
		/	( (	<function> {| <func_name> |} <func_body> ) -> funcDecl )
		/	( (	<local> <function> <ident> <func_body> ) -> locFuncDecl )
		/	( (	<local> {| <name_list> |} ( "=" {| <exp_list> |} )?	) -> locNameList )
	)) -> stmt

	laststat <- ( {} ( 
		<return_stmt> / <break_stmt> 
		) ) -> stmt

	return_stmt <- ( <return> {| <exp_list>? |} ) -> returnStmt

	break_stmt <- ( <break> ) -> breakStmt
	
	varlist <- ( <var> ( "," <var> )* )

	name_list <- ( <ident> ( "," <ident> )* )

	exp_list <- ( <exp> ( "," <exp> )* )
	
	func_call <- ( 
			{|<varorexp>|}  {|<identthenargs>+|}
	) -> funcCall

	exp <- (s <infix_exp> s)
	
	loop_body <-  <do> <block> <end>
		
	rest_of_if <- (
		<exp> <then> <block>
		((<elseif> <rest_of_if> )
		 /(<else> <block> <end>)
		 /<end>)
	) -> ifStmt

	func_name <- ( <ident> ( {"."} <ident> )* ( {":"} <ident> )? )

	infix_exp  <- (
		{| <unar_exp> ( <binop> <unar_exp>)+ |}
	) -> infixExpr / <unar_exp>

	unar_exp <- (
			<unop> <unar_exp>
	) -> unaryExp / <postfix_exp>

	postfix_exp <- ( <nil_expr> / <literal> / ("..." -> identifier) / <funcexpr> / <prefix_exp> / <tableconstructor> )

	prefix_exp <- ( 
			{|<varorexp>|}  {|<identthenargs>*|}
	) -> prefixExp
	
	funcexpr <- (
			<function> <func_body>
	) -> funcExpr
	
	tableconstructor <- (
			"{" s {| <fieldlist>? |} s "}"
	) -> tableConstr
	
	varorexp <- (s(
			<var> / ( "(" <exp> ")" )
	)s)

	identthenargs <- (
			( {":"} <ident> )? <args>
	)
	var <- (s
			( <ident> / "(" <exp> ")"  <varsuffix> ) (<varsuffix>)*
	s)

	varsuffix <- (s(
			(<identthenargs>)*  ( {"["} <exp> "]" / {"."}  <ident> )
	)s)

	args <- (
			"(" {| <exp_list>? |} ")" / {|<tableconstructor>|} / ({|<string> -> literal|}) 
	)

	func_body <- (
			"(" {| <parlist>? |} ")" <block> <end>
	)

	parlist <- (
		<name_list> ("," s {"..."})? / {"..."}
	)

	fieldlist <- (<field> ( <fieldsep> <field> )* <fieldsep>?)

	field <- (s(
			( {"["} <exp> "]" s {"="} <exp> ) / ( <ident> {"="} <exp> ) / <exp>
	)s)

	fieldsep <- (s( "," / ";" )s)

	binop <- ( s { "+" / "-" / "*" / "/" / "^" / "%" / ".." / 
		 "<=" / "<" / ">=" / ">" / "==" / "~=" / 
		 <and> / <or> } s )

	unop <- ( s { "-" / <not> / "#" } s )

	bool_exp <- ( s {<true> / <false> } s ) -> boolean
	
	nil_expr <- <nil> -> nilExpr

	literal <- ( <number> / <bool_exp> / <string> ) -> literal

	number	<- (s{~
		 <hexnum> / <decimal> / <integer>
	~}s) -> tonumber
	
	string	<- (s(
		 <qstring> / <astring> / <lstring>
	)s) -> string

	ident <- (s(
		 { <word> }
	)s) -> identifier

	close		<- (']' {=eq} ']')
	
	captureEquals <- ({ '='* })
	
	local			<- s "local" <idsafe> s
	function	<- s "function" <idsafe> s
	nil				<- s "nil" <idsafe> s
	true			<-   "true" <idsafe> 
	false			<-   "false" <idsafe> 
	return		<- s "return" <idsafe> s
	end				<- s "end" <idsafe> s
	break			<- s "break" <idsafe> s
	not				<-   "not" <idsafe> 
	while			<- s "while" <idsafe> s
	do				<- s "do" <idsafe> s
	for				<- s "for" <idsafe> s
	in				<- s "in" <idsafe> s
	and				<-   "and" <idsafe>
	or				<-   "or" <idsafe>
	if				<- s "if" <idsafe> s
	elseif		<- s "elseif" <idsafe> s
	else			<- s "else" <idsafe> s
	then			<- s "then" <idsafe> s
	repeat		<- s "repeat" <idsafe> s
	until			<- s "until" <idsafe> s
	
	sep <- (( <bcomment>? (<newline> / ";" / &"}" / <lcomment>) / ( !<newline> %s / <newline> ) <sep>? ))

	escape <- ('\' (%digit^3 / .))

	astring <- ( {"'"}  { (<escape> / (!"'" !<newline> .))* } "'" )
	qstring <- ( {'"'}  { (<escape> / !'"' !<newline> .)* } '"' )
	lstring <- ( {'['} ( {:eq: '='* :}) '[' <stringFromDoubleBracket> <close>)

	hexnum <- ( "-"? "0x" %xdigit+ (("p"/"P") <integer>)? )

	decexp <- ( ("e"/"E") "-"? <digits> )

	decimal <- ( "-"? <digits> ("." <digits> <decexp>? / <decexp>) )

	integer <- ( "-"? <digits> )

	stringFromDoubleBracket <- ( {(!<close> <any>)*} )

	any <- ( (!<newline> .) / <newline>)

	lcomment	<- ( {} "--" {(!<newline> .)*} <newline>) -> lcomm
	bcomment	<- ( {} ('--[' {:eq: '='* :} '[' <stringFromDoubleBracket> <close>)) -> bcomm
	comment		<- ( <bcomment> / <lcomment> )
	idsafe		<- ( !(%alnum / "_") )
	s					<- ( (<comment> / ( !<newline> %s / <newline> ))* )
	digits		<- ( %digit (%digit / (&('_' %digit) '_') %digit)* )
	word			<- ( (%alpha / "_") (%alnum / "_")* )

	newline <- (%nl) -> newLine
]]

function M.test:setUp()
	self.parser = require"libs.lpeg.re".compile(M.grammar, require"mad.lang.lua.defs".defs)
end
function M.test:tearDown()
	self.parser = nil
end
--require"lua.tableUtil".printTable(res)
function M.test:binaryOperatorPlus(ut)
	local res = self.parser:match([[local a = 1+2 ]])
	ut:equals(res.body[1].rhs[1].lhs.value, 1)
	ut:equals(res.body[1].rhs[1].rhs.value, 2)
	ut:equals(res.body[1].rhs[1].operator, "+")
end
function M.test:binaryOperatorAnd(ut)
	local res = self.parser:match([[local a = 1 and 2 ]])
	ut:equals(res.body[1].rhs[1].lhs.value, 1)
	ut:equals(res.body[1].rhs[1].rhs.value, 2)
	ut:equals(res.body[1].rhs[1].operator, "and")
end

function M.test:paranExpression(ut)
	local res = self.parser:match([[local a = ( 1 and 2 ) ]])
	ut:equals(res.body[1].rhs[1].lhs.value, 1)
	ut:equals(res.body[1].rhs[1].rhs.value, 2)
	ut:equals(res.body[1].rhs[1].operator, "and")
end

function M.test:UnaryOperatorNot(ut)
	local res = self.parser:match([[local a = not 1 ]])
	ut:equals(res.body[1].rhs[1].argument.value, 1)
	ut:equals(res.body[1].rhs[1].operator, "not")
end

function M.test:functionCall(ut)
	local res = self.parser:match([[ local a = a ( 1 , 2 ) ]])
	ut:equals(res.body[1].rhs[1].arguments[2].value, 2)
	ut:equals(res.body[1].rhs[1].callee.name, "a")
end

function M.test:tableConstr(ut)
	local res = self.parser:match([[ local a = { [ "a" ] = 1 , b = 2 ; 3 } ]])
	ut:equals(res.body[1].rhs[1].implicitExpression[1].value.value, 3)
	ut:equals(res.body[1].rhs[1].explicitExpression[1].value.value, 1)
end

function M.test:var(ut)
	local res = self.parser:match([[ local a = a . b [ 1 ] [ 1 ] : c ( 1 ) ]])
	ut:equals(res.body[1].rhs[1].arguments[1].value, 1)
	ut:equals(res.body[1].rhs[1].callee.operator, ":")
	ut:equals(res.body[1].rhs[1].callee.rhs.name, "c")
	ut:equals(res.body[1].rhs[1].callee.lhs.lhs.rhs.value, 1)
	ut:equals(res.body[1].rhs[1].callee.lhs.lhs.lhs.lhs.name, "a")
	ut:equals(res.body[1].rhs[1].callee.lhs.rhs.value, 1)
end

function M.test:nilExpr(ut)
	local res = self.parser:match([[ local a = nil ]])
	ut:equals(res.body[1].rhs[1].type, "Literal")
	ut:equals(res.body[1].rhs[1].value, nil)
end

function M.test:returnStmt(ut)
	local res = self.parser:match([[ return 1 ]])
	ut:equals(res.body[1].type, "Return")
	ut:equals(res.body[1].values[1].value, 1)
end

function M.test:breakStmt(ut)
	local res = self.parser:match([[ break ]])
	ut:equals(res.body[1].type, "Break")
end

function M.test:locNameList(ut)
	local res = self.parser:match([[ local a ]])
	ut:equals(res.body[1].lhs[1].name, "a")
	ut:equals(res.body[1].localDeclaration, true)
end
function M.test:locNameListWithArgs(ut)
	local res = self.parser:match([[ local a , b = 1 , 2 ]])
	ut:equals(res.body[1].lhs[2].name, "b")
	ut:equals(res.body[1].localDeclaration, true)
	ut:equals(res.body[1].rhs[2].value, 2)
end

function M.test:assignment(ut)
	local res = self.parser:match([[ a , b = 1 , 2 ]])
	ut:equals(res.body[1].lhs[2].name, "b")
	ut:differs(res.body[1].localDeclaration, true)
	ut:equals(res.body[1].rhs[2].value, 2)
end

function M.test:functionDefinition(ut)
	local res = self.parser:match([[ function a ( b ) local b end ]])
	ut:equals(res.body[1].parameters[1].name, "b")
	ut:equals(res.body[1].id.name, "a")
	ut:equals(res.body[1].body.body[1].lhs[1].name, "b")
end

function M.test:forStmt(ut)
	local res = self.parser:match([[ for i = 1 , 2 , 3 do local b end ]])
	ut:equals(res.body[1].init.value, 1)
	ut:equals(res.body[1].last.value, 2)
	ut:equals(res.body[1].step.value, 3)
	ut:equals(res.body[1].body.body[1].lhs[1].name, "b")
end

function M.test:forInStmt(ut)
	local res = self.parser:match([[ for i in a do local b end ]])
	ut:equals(res.body[1].names[1].name, "i")
	ut:equals(res.body[1].expressions[1].name, "a")
	ut:equals(res.body[1].body.body[1].lhs[1].name, "b")
end

function M.test:ifStmt(ut)
	local res = self.parser:match([[ if a then local a elseif b then local b else local c end ]])
	ut:equals(res.body[1].consequent.body[1].lhs[1].name, "a")
	ut:equals(res.body[1].test.name, "a")
	ut:equals(res.body[1].alternate.body[1].consequent.body[1].lhs[1].name, "b")
	ut:equals(res.body[1].alternate.body[1].test.name, "b")
	ut:equals(res.body[1].alternate.body[1].alternate.body[1].lhs[1].name, "c")
end
function M.test:ifExpressionWithParanthesis(ut)
	local res = self.parser:match([[
	if (not true or true) and true then
  	a =  1
	end]])
	ut:equals(res.body[1].consequent.body[1].lhs[1].name, "a")
end

function M.test:doStmt(ut)
	local res = self.parser:match([[ do local a end ]])
	ut:equals(res.body[1].body.body[1].lhs[1].name, "a")
end

-- tests of lexer
function M.test:integer(ut)
	local num = self.parser:match([[local a = 1]])
	ut:equals(num.body[1].rhs[1].value,1)
end
function M.test:decimal(ut)
	local num = self.parser:match([[local a = 1.1]])
	ut:equals(num.body[1].rhs[1].value,1.1)
end
function M.test:hexadecimal(ut)
	local num = self.parser:match([[local a = 0x1e]])
	ut:equals(num.body[1].rhs[1].value,0x1e)
end
function M.test:exponent(ut)
	local num = self.parser:match([[local a =  1.1e-15 ]])
	ut:equals(num.body[1].rhs[1].value,1.1e-15)
end
function M.test:hexExponent(ut)
	local num = self.parser:match([[local a =  0x4Ap-2 ]])
	ut:equals(num.body[1].rhs[1].value,0x4Ap-2)
end

function M.test:doubleDelimiterString(ut)
	local str = self.parser:match([[local a =  "str" ]])
	ut:equals(str.body[1].rhs[1].value, "str")
end
function M.test:singleDelimeterString(ut)
	local str = self.parser:match([[local a =  'str' ]])
	ut:equals(str.body[1].rhs[1].value, "str")
end
function M.test:equalSignLongString(ut)
	local str = self.parser:match([====[local a =  [==[str]==] ]====])
	ut:equals(str.body[1].rhs[1].value, [==[str]==])
end
function M.test:longStringEscape(ut)
	local str = self.parser:match([====[local a = [==[\n]==]]====])
	ut:equals(str.body[1].rhs[1].value, [==[\n]==])
	ut:equals(str.body[1].rhs[1].stringOperator, "==")
end
function M.test:shortStringEscapeA(ut)
	local str = self.parser:match([[local a = "\a"]])
	ut:equals(str.body[1].rhs[1].value, "\\a")
end
function M.test:shortStringEscapeB(ut)
	local str = self.parser:match([[local a = "\b"]])
	ut:equals(str.body[1].rhs[1].value, "\\b")
end
function M.test:shortStringEscapeF(ut)
	local str = self.parser:match([[local a = "\f"]])
	ut:equals(str.body[1].rhs[1].value, "\\f")
end
function M.test:shortStringEscapeN(ut)
	local str = self.parser:match([[local a = "\n"]])
	ut:equals(str.body[1].rhs[1].value, "\\n")
end
function M.test:shortStringEscapeR(ut)
	local str = self.parser:match([[local a = "\r"]])
	ut:equals(str.body[1].rhs[1].value, "\\r")
end
function M.test:shortStringEscapeT(ut)
	local str = self.parser:match([[local a = "\t"]])
	ut:equals(str.body[1].rhs[1].value, "\\t")
end
function M.test:shortStringEscapeV(ut)
	local str = self.parser:match([[local a = "\v"]])
	ut:equals(str.body[1].rhs[1].value, "\\v")
end
function M.test:shortStringEscapeSlash(ut)
	local str = self.parser:match([[local a = "\\"]])
	ut:equals(str.body[1].rhs[1].value, "\\\\")
end
function M.test:shortStringEscapeHyphen(ut)
	local str = self.parser:match([[local a = "\""]])
	ut:equals(str.body[1].rhs[1].value, '\\"')
end
function M.test:shortStringEscapeSingleHypen(ut)
	local str = self.parser:match([[local a = "\'"]])
	ut:equals(str.body[1].rhs[1].value, "\\'")
end
function M.test:shortStringEscapeZ(ut)
	local str = self.parser:match([[local a = "\z"]])
	ut:equals(str.body[1].rhs[1].value, "\\z")
end
function M.test:shortStringEscape0(ut)
	local str = self.parser:match([[local a = "\0"]])
	ut:equals(str.body[1].rhs[1].value, "\\0")
end
function M.test:shortStringEscapexXX(ut)
	local str = self.parser:match([[local a = "\xd2"]])
	ut:equals(str.body[1].rhs[1].value, "\\xd2")
end
function M.test:shortStringEscapeDDD(ut)
	local str = self.parser:match([[ local a = "\123" ]])
	ut:equals(str.body[1].rhs[1].value, "\\123")
end

function M.test:boolTrue(ut)
	local str = self.parser:match([[ local a = true ]])
	ut:equals(str.body[1].rhs[1].value, true)
end
function M.test:boolFalse(ut)
	local str = self.parser:match([[ local a = false ]])
	ut:equals(str.body[1].rhs[1].value, false)
end

function M.test:ident(ut)
	local res = self.parser:match([[ local functioner ]])
	ut:equals(res.body[1].lhs[1].name, "functioner")
end

function M.test:lcomment(ut)
	local res = self.parser:match([[local a = 1 --This is a comment
	]])
	ut:equals(res.body[1].rhs[1].value, 1)
end
function M.test:bcomment(ut)
	local res = self.parser:match([==[local a = 1 --[=[This is a comment]=]]==])
	ut:equals(res.body[1].rhs[1].value, 1)
end




return M
