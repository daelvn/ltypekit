-- ltype | 25.11.2018
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
  resolve: (val, resolvers) ->
    for resolver in *resolvers
      val_type = resolver val
      if val_type then return val_type
    val_type = type_ val
    return val_type or false

  add_resolver: (resolver)        => table.insert @resolvers, resolver
  add_allowed:  (allowed)         => table.insert @types,     allowed
  add_type:     (resolver, typel) =>
    table.insert @resolvers, resolver
    for allowed in *typel do table.insert @types, allowed

  resolves: (type_) =>
    with _ @resolvers
      \contains type_
}, {
  __call: (val) => @.resolve val, @resolvers
}

return {:type}
