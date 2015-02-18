local M = { help = {}, _id = "mad.initializer.lambda", _author = "Martin Valen", _year = 2013 }

-- MAD -------------------------------------------------------------------------

M.help.self = [[
NAME
mad.initializer.lambda -- MAD module containing helper functions for the lambda-function.

SYNOPSIS
local lambda = require "mad.initializer.lambda"

DESCRIPTION
Allows one to create functions of type "lambda".
local a = lambda.new(function() return a+b end, true) is the same as \ a+b in mad.

RETURN VALUES
The table of modules and services.

SEE ALSO
None
]]

-- globals ---------------------------------------------------------------------

--Introduces a new type, lambda
local oldType = _G.type
_G.type = function(obj)
        if oldType(obj) == "table" and obj.lambda then
                return "lambda"
        else
                return oldType(obj)
        end
end

-- methods ---------------------------------------------------------------------

M.help.new = [[
        new(funcDecl, noArgs) creates a new lambda function.
        Params:
                funcDecl is a function declaration, which will become the lambda function.
                noArgs says whether this function has no arguments or not.
        Return values:
                Returns a lambda function.
]]

M.new = function (o, noArgs)
  if type(o) == "function" then
                local table = {}
                table._lambda = true
                table._noArgs = noArgs or false
                table._func = o
                setmetatable(table, {
                        __call = function (t,...)
                                return t._func(...)
                        end })
    return table
  end
  error ("invalid lambda argument, should be function")
end

M.help.__eval = [[
__eval(obj) returns the evaluated results of an identifier.
]]

function M.__eval(obj)
        if type(obj) == "table" and obj._lambda then
                if obj._noArgs then
                        return obj._func()
                else
                        error("A lambda with arguments can't be called without parentheses.",2)
                end
        else
                return obj
        end
end

-- tests ---------------------------------------------------------------------

function M.testLambda()
        local lambda = M

        local function returnA()
                return (lambda.__eval(a))
        end

        a = lambda.new( -- \ \ k
                function()
                        return lambda.__eval( -- \ k
                                lambda.new(
                                        function()
                                                return k
                                        end
                                ,true)
                        )
                end
        ,true)
        k = 2
        returnA()
        k = "a is a lambdalambdastring"
        returnA()

        a()

        a = lambda.new( function(c,b) return (c+b) end,false) -- \c,b c+b
        a(1,1)
        print("All tests passed.")
end

-- end -------------------------------------------------------------------------

return M
