local type_ = type
local has_meta
has_meta = function(val)
  local val_mt = getmetatable(val)
  if val_mt then
    if (type_(val_mt.__type)) == "function" then
      return val_mt.__type(val)
    else
      return val_mt.__type
    end
  else
    return false
  end
end
local is_io
is_io = function(val)
  return (io.type(val)) and "io" or false
end
local type = setmetatable({
  resolvers = {
    has_meta,
    is_io
  },
  types = {
    "string",
    "number",
    "boolean",
    "userdata",
    "function",
    "table",
    "io",
    "signed",
    "signed_constructor"
  },
  resolve = function(val, resolvers)
    for _index_0 = 1, #resolvers do
      local resolver = resolvers[_index_0]
      local val_type = resolver(val)
      if val_type then
        return val_type
      end
    end
    local val_type = type_(val)
    return val_type or false
  end
}, {
  __call = function(self, val)
    return self.resolve(val, self.resolvers)
  end
})
return {
  type = type
}
