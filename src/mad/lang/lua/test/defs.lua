local Mod = {}
local Mod = {}
local mt = {}; setmetatable(Mod, mt)
mt.__call = function (_, M)

    function M.test:setUp()
	    self.variable = defs.identifier("dummy")
	    self.backUpVariable = defs.identifier("Another")
	    self.expression = self.variable
	    self.backUpExpression = self.backUpVariable
	    self.statement = defs.stmt(1,self.variable)
    end

    function M.test:tearDown()
	    self.variable = nil
	    self.backUpVariable = nil
	    self.expression = nil
	    self.backUpExpression = nil
	    self.statement = nil
    end

    function M.test:error( ut )
	    ut:fails(defs.error,[[a = 1]], 0)
    end

    function M.test:chunk(ut)
	    local result = defs.chunk({ self.statement })
	    ut:equals(result.type, "Chunk")
	    ut:equals(result.body[1], self.statement)
    end

    function M.test:literal( ut )
	    local result = defs.literal(1)
	    ut:equals(result.type, "Literal")
    end
    function M.test:nilExpr( ut )
	    local result = defs.nilExpr(1)
	    ut:equals(result.type, "Literal")
    end
    function M.test:identifier( ut )
	    local result = defs.identifier(1)
	    ut:equals(result.type, "Variable")
    end
    function M.test:stmt( ut )
	    local result = defs.stmt(13, defs.identifier("hello"))
	    ut:equals(result.type, "Variable")
	    ut:equals(result.pos, 13)
    end
    function M.test:ifStmt( ut )
	    local result = defs.ifStmt(self.expression, self.statement)
	    ut:equals(result.type, "If")
	    ut:equals(result.test, self.expression)
	    ut:differs(result.consequent.type, self.statement.type)
    end
    function M.test:whileStmt( ut )
	    local result = defs.whileStmt(self.expression, defs.blockStmt{self.statement})
	    ut:equals(result.type, "Loop")
	    ut:equals(result.kind, "While")
	    ut:equals(result.test, self.expression)
	    ut:equals(result.step, nil)
	    ut:equals(result.body.body[1], self.statement)
    end
    function M.test:repeatStmt( ut )
	    local result = defs.repeatStmt(defs.blockStmt{self.statement}, self.expression)
	    ut:equals(result.type, "Loop")
	    ut:equals(result.kind, "Repeat")
	    ut:equals(result.test, self.expression)
	    ut:equals(result.step, nil)
	    ut:equals(result.body.body[1], self.statement)
    end
    function M.test:forStmt( ut )
	    local result = defs.forStmt("forstmt", self.expression, self.expression, defs.literal(1), defs.blockStmt{self.statement})
	    ut:equals(result.type, "Loop")
	    ut:equals(result.kind, "For")
	    ut:equals(result.last, self.expression)
	    ut:equals(result.init, self.expression)
	    ut:equals(result.name, "forstmt")
	    ut:equals(result.step.value, 1)
	    ut:equals(result.body.body[1], self.statement)
    end
    function M.test:forInStmt( ut )
	    local result = defs.forInStmt(self.expression, self.expression, defs.blockStmt{self.statement})
	    ut:equals(result.type, "GenericFor")
	    ut:equals(result.names, self.expression)
	    ut:equals(result.expressions, self.expression)
	    ut:equals(result.step, nil)
	    ut:equals(result.body.body[1], self.statement)
    end
    function M.test:funcDecl( ut )
	    local result = defs.funcDecl("funcname", {self.variable}, defs.blockStmt{self.statement})
	    ut:equals(result.type, "FunctionDefinition")
	    ut:equals(result.id, "funcname")
	    ut:equals(result.parameters[1], self.variable)
	    ut:equals(result.body.body[1], self.statement)
	    ut:differs(result.expression, true)
    end
    function M.test:funcExpr( ut )
	    local result = defs.funcExpr({self.variable}, defs.blockStmt{self.statement})
	    ut:equals(result.type, "FunctionDefinition")
	    ut:equals(result.id, nil)
	    ut:equals(result.parameters[1], self.variable)
	    ut:equals(result.body.body[1], self.statement)
	    ut:equals(result.expression, true)
    end
    function M.test:blockStmt( ut )
	    local result = defs.blockStmt{self.statement}
	    ut:equals(result.type, "Block")
	    ut:equals(result.body[1], self.statement)
    end
    function M.test:returnStmt( ut )
	    local result = defs.returnStmt{self.expression}
	    ut:equals(result.type, "Return")
	    ut:equals(result.values[1], self.expression)
    end
    function M.test:breakStmt( ut )
	    local result = defs.breakStmt()
	    ut:equals(result.type, "Break")
    end
    function M.test:exprStmt( ut )
	    local result = defs.exprStmt(1, self.expression)
	    ut:equals(result.type, self.expression.type)
    end
    function M.test:unaryExp( ut )
	    local result = defs.unaryExp("-", self.variable)
	    ut:equals(result.type, "UnaryExpression")
	    ut:equals(result.argument.type, self.variable.type)
	    ut:equals(result.operator, "-")
    end
    function M.test:funcCall( ut )
	    local result = defs.funcCall({defs.identifier("table")},{":", defs.identifier("func"), {self.expression}})
	    ut:equals(result.type, "FunctionCall")
	    ut:equals(result.callee.type, "BinaryExpression")
	    ut:equals(result.callee.lhs.name, "table")
	    ut:equals(result.callee.rhs.name, "func")
	    ut:equals(#result.arguments, 1)
	    ut:equals(result.arguments[1], self.expression)
	    ut:equals(result.callee.operator, ":")
    end
    function M.test:binaryExpr( ut )
	    local result = defs.binaryExpr("+",self.expression,self.backUpExpression)
	    ut:equals(result.operator, "+")
	    ut:equals(result.lhs, self.expression)
	    ut:equals(result.rhs, self.backUpExpression)
    end
    function M.test:varlistAssign( ut )
	    local result = defs.varlistAssign({self.variable, self.backUpVariable},{self.expression, self.backUpExpression})
	    ut:equals(#result.lhs,2)
	    ut:equals(#result.rhs,2)
	    ut:equals(result.rhs[2], self.backUpExpression)
	    ut:equals(result.lhs[1], self.variable)
    end
    function M.test:locFuncDecl( ut )
	    local result = defs.locFuncDecl(defs.identifier("name"), {self.expression}, defs.blockStmt{self.statement})
	    ut:equals(result.type, "FunctionDefinition")
	    ut:equals(result.localDeclaration, true)
    end
    function M.test:locNameList( ut )
	    local test1 = defs.locNameList({self.variable})
	    local test2 = defs.locNameList({self.variable, self.backUpVariable}, {self.expression, self.backUpExpression})
	    ut:equals(test1.rhs, nil)
	    ut:equals(test1.lhs[1], self.variable)
	    ut:equals(test1.localDeclaration, true)
	    ut:equals(test2.rhs[2], self.backUpExpression)
	    ut:equals(test2.lhs[1], self.variable)
	    ut:equals(test2.localDeclaration, true)
    end
    function M.test:tableConstr( ut )
	    local result = defs.tableConstr({ self.expression, "[", self.expression, "=", self.backUpExpression, self.variable, "=", self.expression })
	    ut:equals(result.explicitExpression[1].computed, true)
	    ut:equals(result.explicitExpression[1].key, self.expression)
	    ut:equals(result.explicitExpression[1].value, self.backUpExpression)
	    ut:equals(result.explicitExpression[2].computed, false)
	    ut:equals(result.explicitExpression[2].key, self.variable)
	    ut:equals(result.explicitExpression[2].value, self.expression)
	    ut:equals(result.implicitExpression[1].value, self.expression)
    end
    function M.test:prefixExp( ut )
	    local result = defs.prefixExp({self.variable, ".", self.backUpVariable}, {})
	    ut:equals(result.type, "BinaryExpression")
	    ut:equals(result.operator, ".")
	    ut:equals(result.lhs, self.variable)
	    ut:equals(result.rhs, self.backUpVariable)
    end

    function M.test:tableAccess( ut )
	    local result = defs.tableAccess(self.variable, self.backUpVariable, ".")
	    ut:equals(result.type, "BinaryExpression")
	    ut:equals(result.operator, ".")
	    ut:equals(result.lhs, self.variable)
	    ut:equals(result.rhs, self.backUpVariable)
    end

    function M.test:doStmt( ut )
	    local result = defs.doStmt(defs.blockStmt{self.statement})
	    ut:equals(result.type, "Do")
	    ut:equals(result.body.body[1], self.statement)	
    end

end

return Mod
