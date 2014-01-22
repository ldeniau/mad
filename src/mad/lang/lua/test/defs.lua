local M = {}

function M:setUp()
    self.defs = require"mad.lang.lua.defs".defs
    self.variable = self.defs.identifier("dummy")
    self.backUpVariable = self.defs.identifier("Another")
    self.expression = self.variable
    self.backUpExpression = self.backUpVariable
    self.statement = self.defs.stmt(1,self.variable)
end

function M:tearDown()
    self.variable = nil
    self.backUpVariable = nil
    self.expression = nil
    self.backUpExpression = nil
    self.statement = nil
end

function M:error( ut )
    ut:fails(self.defs.error,[[a = 1]], 0)
end

function M:chunk(ut)
    local result = self.defs.chunk({ self.statement })
    ut:equals(result.type, "Chunk")
    ut:equals(result.body[1], self.statement)
end

function M:literal( ut )
    local result = self.defs.literal(1)
    ut:equals(result.type, "Literal")
end
function M:nilExpr( ut )
    local result = self.defs.nilExpr(1)
    ut:equals(result.type, "Literal")
end
function M:identifier( ut )
    local result = self.defs.identifier(1)
    ut:equals(result.type, "Variable")
end
function M:stmt( ut )
    local result = self.defs.stmt(13, self.defs.identifier("hello"))
    ut:equals(result.type, "Variable")
    ut:equals(result.pos, 13)
end
function M:ifStmt( ut )
    local result = self.defs.ifStmt(self.expression, self.statement)
    ut:equals(result.type, "If")
    ut:equals(result.test, self.expression)
    ut:differs(result.consequent.type, self.statement.type)
end
function M:whileStmt( ut )
    local result = self.defs.whileStmt(self.expression, self.defs.blockStmt{self.statement})
    ut:equals(result.type, "Loop")
    ut:equals(result.kind, "While")
    ut:equals(result.test, self.expression)
    ut:equals(result.step, nil)
    ut:equals(result.body.body[1], self.statement)
end
function M:repeatStmt( ut )
    local result = self.defs.repeatStmt(self.defs.blockStmt{self.statement}, self.expression)
    ut:equals(result.type, "Loop")
    ut:equals(result.kind, "Repeat")
    ut:equals(result.test, self.expression)
    ut:equals(result.step, nil)
    ut:equals(result.body.body[1], self.statement)
end
function M:forStmt( ut )
    local result = self.defs.forStmt("forstmt", self.expression, self.expression, self.defs.literal(1), self.defs.blockStmt{self.statement})
    ut:equals(result.type, "Loop")
    ut:equals(result.kind, "For")
    ut:equals(result.last, self.expression)
    ut:equals(result.init, self.expression)
    ut:equals(result.name, "forstmt")
    ut:equals(result.step.value, 1)
    ut:equals(result.body.body[1], self.statement)
end
function M:forInStmt( ut )
    local result = self.defs.forInStmt(self.expression, self.expression, self.defs.blockStmt{self.statement})
    ut:equals(result.type, "GenericFor")
    ut:equals(result.names, self.expression)
    ut:equals(result.expressions, self.expression)
    ut:equals(result.step, nil)
    ut:equals(result.body.body[1], self.statement)
end
function M:funcDecl( ut )
    local result = self.defs.funcDecl("funcname", {self.variable}, self.defs.blockStmt{self.statement})
    ut:equals(result.type, "FunctionDefinition")
    ut:equals(result.id, "funcname")
    ut:equals(result.parameters[1], self.variable)
    ut:equals(result.body.body[1], self.statement)
    ut:differs(result.expression, true)
end
function M:funcExpr( ut )
    local result = self.defs.funcExpr({self.variable}, self.defs.blockStmt{self.statement})
    ut:equals(result.type, "FunctionDefinition")
    ut:equals(result.id, nil)
    ut:equals(result.parameters[1], self.variable)
    ut:equals(result.body.body[1], self.statement)
    ut:equals(result.expression, true)
end
function M:blockStmt( ut )
    local result = self.defs.blockStmt{self.statement}
    ut:equals(result.type, "Block")
    ut:equals(result.body[1], self.statement)
end
function M:returnStmt( ut )
    local result = self.defs.returnStmt{self.expression}
    ut:equals(result.type, "Return")
    ut:equals(result.values[1], self.expression)
end
function M:breakStmt( ut )
    local result = self.defs.breakStmt()
    ut:equals(result.type, "Break")
end
function M:exprStmt( ut )
    local result = self.defs.exprStmt(1, self.expression)
    ut:equals(result.type, self.expression.type)
end
function M:unaryExp( ut )
    local result = self.defs.unaryExp("-", self.variable)
    ut:equals(result.type, "UnaryExpression")
    ut:equals(result.argument.type, self.variable.type)
    ut:equals(result.operator, "-")
end
function M:funcCall( ut )
    local result = self.defs.funcCall({self.defs.identifier("table")},{":", self.defs.identifier("func"), {self.expression}})
    ut:equals(result.type, "FunctionCall")
    ut:equals(result.callee.type, "BinaryExpression")
    ut:equals(result.callee.lhs.name, "table")
    ut:equals(result.callee.rhs.name, "func")
    ut:equals(#result.arguments, 1)
    ut:equals(result.arguments[1], self.expression)
    ut:equals(result.callee.operator, ":")
end
function M:binaryExpr( ut )
    local result = self.defs.binaryExpr("+",self.expression,self.backUpExpression)
    ut:equals(result.operator, "+")
    ut:equals(result.lhs, self.expression)
    ut:equals(result.rhs, self.backUpExpression)
end
function M:varlistAssign( ut )
    local result = self.defs.varlistAssign({self.variable, self.backUpVariable},{self.expression, self.backUpExpression})
    ut:equals(#result.lhs,2)
    ut:equals(#result.rhs,2)
    ut:equals(result.rhs[2], self.backUpExpression)
    ut:equals(result.lhs[1], self.variable)
end
function M:locFuncDecl( ut )
    local result = self.defs.locFuncDecl(self.defs.identifier("name"), {self.expression}, self.defs.blockStmt{self.statement})
    ut:equals(result.type, "FunctionDefinition")
    ut:equals(result.localDeclaration, true)
end
function M:locNameList( ut )
    local test1 = self.defs.locNameList({self.variable})
    local test2 = self.defs.locNameList({self.variable, self.backUpVariable}, {self.expression, self.backUpExpression})
    ut:equals(test1.rhs, nil)
    ut:equals(test1.lhs[1], self.variable)
    ut:equals(test1.localDeclaration, true)
    ut:equals(test2.rhs[2], self.backUpExpression)
    ut:equals(test2.lhs[1], self.variable)
    ut:equals(test2.localDeclaration, true)
end
function M:tableConstr( ut )
    local result = self.defs.tableConstr({ self.expression, "[", self.expression, "=", self.backUpExpression, self.variable, "=", self.expression })
    ut:equals(result.explicitExpression[1].computed, true)
    ut:equals(result.explicitExpression[1].key, self.expression)
    ut:equals(result.explicitExpression[1].value, self.backUpExpression)
    ut:equals(result.explicitExpression[2].computed, false)
    ut:equals(result.explicitExpression[2].key, self.variable)
    ut:equals(result.explicitExpression[2].value, self.expression)
    ut:equals(result.implicitExpression[1].value, self.expression)
end
function M:prefixExp( ut )
    local result = self.defs.prefixExp({self.variable, ".", self.backUpVariable}, {})
    ut:equals(result.type, "BinaryExpression")
    ut:equals(result.operator, ".")
    ut:equals(result.lhs, self.variable)
    ut:equals(result.rhs, self.backUpVariable)
end

function M:tableAccess( ut )
    local result = self.defs.tableAccess(self.variable, self.backUpVariable, ".")
    ut:equals(result.type, "BinaryExpression")
    ut:equals(result.operator, ".")
    ut:equals(result.lhs, self.variable)
    ut:equals(result.rhs, self.backUpVariable)
end

function M:doStmt( ut )
    local result = self.defs.doStmt(self.defs.blockStmt{self.statement})
    ut:equals(result.type, "Do")
    ut:equals(result.body.body[1], self.statement)	
end

return M
