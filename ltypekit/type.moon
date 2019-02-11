--> # ltypekit6/type
--> Type checking library
-- 13.01.2019
-- By daelvn
type_ = type

--> # dieA
--> Annotation error
dieA = (s) =>
  print color "%{red}[ERROR] #{s}"
  print color "%{white}        In type constructor for type %{yellow}#{@T.name}"
  print color "        Type annotation: %{green}#{@T.annotation}"
  error!

--> # Resolvers
--> Resolvers are function which take in any value and return something depending on
--> whether it can resolve the type or not.
--> Resolvers such as [has_meta](#has_meta) will return the string of the type. Some
--> others, such as [IO](#IO) return a boolean value, since the type is guessed from
--> the resolver function's name.
--> ## Issues with overlapping
--> You should make sure that your resolver *only* resolves your type, so that not
--> all tables, for example, are marked as your "Collection" type. If your type is
--> too simple to be easily confused (say, a Point), you should consider creating a
--> __type metamethod which gives the "Point" value. You can do this easily using
--> the [metatype] function.

--> # typeof
--> Returns the type of a value
typeof = setmetatable {
  -- List of resolvers
  resolvers: {
    --> ## has_meta
    --> Checks the meta element of 
    has_meta: (a) ->
      mt = getmetatable a
      if mt
        if (type_ mt.__type) == "function" then return mt.__type a
        else                                    return mt.__type
      else false
    --> ## IO
    --> Returns true for IO handles
    IO: (a) -> (io.type a) and true or false
  }

  --> ## add
  --> Adds a raw type to `typeof`
  add: (xt, resolver) => @resolvers[xt] = resolver

  --> ## new
  --> Adds a new type to `typeof` using a template
  new: (T) => @resolvers[T.name] = T.resolver

  --> ## resolve
  --> Resolves a value, main function for typeof
  resolve: (val, resolverl) ->
    for T, resolver in pairs resolverl
      resolved = resolver val
      switch type_ resolved
        when "string"  then return resolved
        when "boolean" then if resolved then return T else continue
    return (type_ val) or false

  --> ## resolves
  --> If `typeof` can resolve `a`, it will return `true` and the name of the type, otherwise just false
  resolves: (xt) =>
    for T, resolver in pairs @resolvers do
      resolved = resolver xt
      switch type_ resolved
        when "string"  then return resolved
        when "boolean" then if true then return true, T else continue
    return false

}, {
  __call: (val) => @.resolve val, @resolvers
}

--> # typeE
--> Creates a type template using a name and an annotation
typeE = (name="?", annotation="") -> {:name, annotation: "#{name}#{annotation and " #{annotation}" or ""}"}

--> # wrapConstructor
--> Wraps a constructor to support type annotations and argument checking
wrapConstructor = (T, cons, annot) ->
  types = [xt for xt in annot\gmatch "%S"]
  table.remove types, 1
  (...) ->
    argl = {...}
    if #argl != #types
      dieA {:T}, "Number of arguments in annotation does not match. Expected #{#types}, got #{#argl}"
    for i=1,#argl
      if argl[i] != types[i]
        dieA {:T}, "Unmatching types in annotation. Expected #{types[i]}, got #{argl[i]}"
    cons ...

--> # data
--> Creates a new, single type with a several constructors using a simple resolver.
--> It takes a type template `T` (any table) and a definition table.
--> It also will automatically test itself in case the constructor does not generate
--> a valid type.
--> ```moon
--> -- example.moon
--> --------------------------
--> Char, newChar = typeE "Char", "string"
--> data Char, {
-->   name:         "Char"
-->   annotation:   "Char string"
-->   resolver:     (v) -> ((type v)=="string") and (#v==1)
-->   constructors: {Char, newChar}
-->   constructor:  (v) -> v\sub 1,1
--> }
--> typeof newChar "x" -- Char
--> ```
data = (T, def) ->
  T.name       or= def.name
  T.resolver   or= def.resolver
  T.annotation or= def.annotation
  for constructor in *def.constructors
    (getmetatable constructor).__call = wrapConstructor T, def.constructor, T.annotation
  typeof\new T

--> # metatype
--> Creates a constructor for any type (using `__type`).
--> ```moon
--> -- example.moon
--> --------------------------
--> Container = typeE "Container", "number string"
--> metatype Container, (n, s) -> {id: n, name: s}
--> typeof Container 5, "name" -- Container
--> ```
metatype = (T, cons) -> (getmetatable T).__call = wrapConstructor T, cons, T.annotation

--> # typeforall
--> Checks that all values in the list are of the same type. If so, returns the type name, otherwise false.
typeforall = (t) ->
  name   = type t[1]
  status = true
  for value in *t[2,]
    if (typeof value) != name
      status = false
      break
  return if status then name else false

--> # typeforany
--> Returns all the possible types in a table
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
{ :typeof, :typeforall, :typeforany, :data, :metatype, :typeE }
