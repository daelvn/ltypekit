--> # ltypekit
--> Advanced type checking library for Lua.
--> ## ltypekit/type
--> `typeof` function provider and generic type resolvers.
-- ltypekit.7/type
-- By daelvn
-- 01.03.2019
type_ = type

--> # Native type checking
--> Provide functions to check the native types.
--> ## equals
--> Function to compare types and optionally provide tables.
equals = (any) -> (any_) ->
  switch type_ any
    when "string"
      switch type_ any_
        when "string"
          any == any_
        when "table"
          for v in *any_
            return true if any == v
    when "table"
      switch type_ any_
        when "string"
          for v in *any
            return true if any_ == v
        when "table"
          any == any_
--> ## isX
--> Create type checkers provided a resolver and a string to check for.
isX = (resolver) ->
  if (type_ resolver) != "function" then error "ltypekit :: Wrong argument to isX. Expected function, got #{type_ resolver}"
  (target) ->
    if (type_ target) != "string"   then error "ltypekit :: Wrong argument to isX. Expected string, got #{type_ resolver}"
    (any) -> ((equals (resolver any)) target) and any or false
--> ## nativeIsX
--> [isX](#isX) with the native type function already provided.
nativeIsX = isX type_
--> ## isNative
--> Checks that a type is supported by the native type resolver.
isNative = nativeIsX { "number", "string", "function", "thread", "nil", "userdata", "table", "boolean" }
--> ## isString
--> Checks that the value passed is a string.
isString = nativeIsX "string"
--> ## isTable
--> Checks that the value passed is a table.
isTable = nativeIsX "table"
--> ## isCallable
--> Checks that the value passed is callable
isCallable = (v) ->
  ((nativeIsX "function") v) or
  (getmetatable v).__call

--> # Resolvers
--> Resolvers are functions which take in any value and return a string value depending on whether it can resolve the
--> type or not.
--> ## Issues with overlapping
--> You should make sure that your resolver *only* resolves your type, so for example, not all tables are mistaken with
--> your type. Most of the times you should be able to use a `__type` metamethod.

--> ### hasMeta
--> Checks for a `__type` metamethod. It can be either a function or a string.
--> If it is a function, it will be called with the value as an argument.
--> #### Dynamic types
--> As `hasMeta` allows you to have a function be called with the value, the type returned can depend on the value. This
--> means that you can define a single type (`Boolean`) and have it return two types (`True` or `False`).
hasMeta = (any) ->
  typeMeta = (getmetatable any).__type
  switch type_ typeMeta
    when "function" then isString typeMeta any
    when "string"   then isString typeMeta
    else                 false

--> ### isIO
--> Checks whether it is an `io` module handle.
isIO = (any) -> (io.type a) and "IO" or false

--> # typeof
--> Returns the type of a value. It requires to be a table with methods to exploit the mutability of Lua tables.
--> However, there are external functions which let the user have a more "functional" syntax.
typeof = setmetatable {
  --> type_ is not included since it is the default fallback.
  resolvers: { hasMeta, isIO }
  --> ## resolve
  --> Resolves a value given a list of resolvers.
  resolve: (any, resolvers) ->
    for resolver in *resolverl
      resolved = resolver any
      switch type_ resolved
        when "string" then resolved
        else               continue
    (type_ val) or false

  --> ## add
  --> Adds a new type to `typeof`
  add: (resolver) => table.insert @resolvers, resolver
}, {
  __call: (any) => @.resolve val, @resolvers
}

--> ## Typeof functional syntax
addResolver = (resolver) -> typeof\add resolver

--> # typeforall
--> Checks that all values in the list are of the same type. If so, returns the type name, otherwise false.
typeforall = (t) ->
  name   = typeof t[1]
  status = true
  for value in *t[2,]
    if (typeof value) != name
      status = false
      break
  status and name else false

--> # typeforany
--> Returns all the possible types in a table.
typeforany = (t) ->
  possible = {}
  already  = {}
  for value in *t
    xt = typeof value
    unless already[xt]
      table.insert possible, xt
      already[xt] = true
  possible

--> Return
{ :typeof, :typeforall, :typeforany
  :isX, :nativeIsX, :isNative, :isString, :isTable, :isCallable
  :hasMeta, :isIO
  :addResolver }
