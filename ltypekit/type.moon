-- ltypekit | 25.11.2018
-- By daelvn
-- Custom type resolver
--   Based on typical and mtype
type_ = type

-- Resolvers
has_meta = (val) ->
  val_mt = getmetatable val
  if val_mt
    if (type_ val_mt.__type) == "function" then return val_mt.__type val
    else                                        return val_mt.__type
  else return false
is_io       = (val) -> (io.type val) and "io" or false

type = setmetatable {
  -- do not add resolvers that work for more types than yours (type_) since
  -- it could catch another value which shouldn't.
  resolvers: {has_meta, is_io} -- type_ is not included so that users can add their own before type_
  types: {
    "string", "number", "boolean", "userdata", "function", "table"
    "io"
    "signed", "signed_constructor"
  }
  libraries: {}
  resolve: (val, resolvers) ->
    for rname, resolver in pairs resolvers
      val_type = resolver val
      if val_type then return val_type
    val_type = type_ val
    return val_type or false

  add_resolver: (resolver)        => table.insert @resolvers, resolver
  add_allowed:  (allowed)         => table.insert @types,     allowed
  add_types:    (typel, resolver) =>
    table.insert @resolvers, resolver
    for allowed in *typel do table.insert @types, allowed
  add:          (xtype, resolver) =>
    table.insert @resolvers, resolver
    table.insert @types,     xtype

  export: (xtype, resolver) => {:resolver, type: xtype, lib: (libraries[xtype] or {})}
  import: (exported) =>
    table.insert @resolvers, exported.resolver
    table.insert @types,     exported.type

  set_library: (xtype, lib) => @libraries[xtype] = lib
  libfor:      (xtype)      => @libraries[xtype]

  resolves: (xtype) =>
    for t in *@types do if xtype == t then return true
    false
}, {
  __call: (val) => @.resolve val, @resolvers
}
typeof = type

-- Checks that all values in the list are of the same type. If so, returns the type name, otherwise false.
typeforall = (t) ->
  name   = type t[1]
  status = true
  for value in *t[2,]
    if (typeof value) != name
      status = false
      break
  return if status then name else false

libfor = (xtype) -> typeof\libfor xtype

return { :type, :typeof, :typeforall, :libfor }
