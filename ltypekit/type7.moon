--> # ltypekit7/type
--> Custom type resolver
-- 10.01.2019
-- By daelvn
import dieA   from require "ltypekit.util"
import printi from require "ltext"
type_   = type
select_ = select

select = (...) -> select_ 1, ...

--> # Annotation errors


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
--> the [newtype] function.

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
  --> Adds a type using a type template.
  add: (T) => @resolvers[T.name] = T.resolver
  --> ## new
  --> Creates a new type on the fly. To be used with Char-like types
  new: (T, resolver) => @resolvers[T] = resolver

  --> ## resolve
  --> Resolves a value, main function for typeof
  resolve: (val, resolverl) ->
    for T, resolver in pairs resolverl
      resolved = resolver val
      switch type_ resolved
        when "string"  then return resolved
        when "boolean" then if resolved then return T else continue
    return (type_ val) or false

  --> ## can_resolve
  --> typeof` can resolve `a`, it will return `true If, and the name of the type, otherwise just false
  can_resolve: (a) =>
    for T, resolver in pairs @resolvers do
      resolved = resolver a
      switch type_ resolved
        when "string"  then return resolved
        when "boolean" then if true then return true, T else continue
    return false
}, {
  __call: (val) => @.resolve val, @resolvers
}

--> # typeE
--> Creates a new type template. Used for [newtype](#newtype) and [typedef](#typedef)
typeE = (name="?") -> {
  :name
  resolver:     -> false
  constructors: {}
}

--> # constE
--> Creates a new constructor template. Used for [data](#data)
constE = (name="?") -> {
  :name
  produces:    false
  constructor: -> false
}

--> # newtype
--> Creates a new table-based type with a single constructor.
--> ## Example
--> ```moon
--> Point = typeE "Point"
--> newtype Point, (v) -> (#v == 2) and ((type v.x) == "number") and ((type v.y) == "number")
--> typeof\add Point
--> ```
newtype = (template, ...) ->
  -- Collect arguments
  argl              = {...}
  -- Check number of arguments
  argn              = select_ '#', ...
  -- Last is always resolver
  resolver          = argl[argn]
  -- Collect parameters
  parameters        = {}
  if argn > 1 then for param in *argl[,argn-1] do table.insert parameters, param
  -- Set resolver
  template.resolver   = resolver
  -- Create annotation
  template.annotation = "#{template.name}"
  for param in *parameters do template.annotation ..= " #{param}"
  -- Save parameters
  template.parameters = parameters
  -- Register type
  typeof\add template

--> # constructor
--> Create constructors for a type
constructor = (templateT, templateC, con) ->
  templateC.produces    = templateT
  templateC.constructor = (...) ->
    argn = select_ '#', ...
    if argn != #templateT.parameters then
      dieA {C: templateC, T: templateT}, "Too many parameters. Passed #{argn}, expected #{#templateT.parameters}"
    con ...
  --
  table.insert templateT.constructors, templateC.constructor
  --
  setmetatable templateC, {
    __call: (...) => @.constructor ...
  }


Point = typeE "Point"
Coord = constE "Coord"
newtype Point, "x", "y" , (...) ->
  val      = select ...
  -- Constructors
  do
    constructor Point, Coord , (...) ->
      x, y = select ...
      {:x, :y}
    constructor Point, Point , (...) ->
      print "using self as constructor"
      x, y = select ...
      {:x, :y}
  -- Resolver
  ((type_ val)   == "table")  and
  ((type_ val.x) == "number") and
  ((type_ val.y) == "number")

print typeof x: 2, y: 3
print Point.annotation
print typeof Coord 2, 3
--print typeof Point 2, 3, 6

char_resolver = (v) -> ((type_ v) == "string") and
                       (v\len!    == 1       ) and
                       "char" or false
typeof\new "char", char_resolver

print typeof "asd"
print typeof "a"
