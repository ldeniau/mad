local M = { help={}, test={}, _author="MV", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  luaBase

SYNOPSIS
  local lexer = require"mad.lang.parser.pattern.lexer"

DESCRIPTION
  Returns a regex-based grammar. More spesific the grammar of the base of lua

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- grammar ---------------------------------------------------------------------

M.pattern = [[	

	close		<- (']' =eq ']') / {(!']' .)*}

	lcomment	<- ({} (!%nl %s)* "--" {(!%nl .)*} %nl) -> lcomm
	bcomment	<- ({} ('--[' {:eq: '='* :} '[' <close>)) -> bcomm
	comment		<- <bcomment> / <lcomment>
	idsafe		<- !(%alnum / "_")
	s					<- (<comment> / %s)*
	S					<- (<comment> / %s)+
	hs				<- (!%nl %s)*
	HS				<- (!%nl %s)+
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

	sep <- <bcomment>? (%nl / ";" / &"}" / <lcomment>) / %s <sep>?

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
]]

return M
