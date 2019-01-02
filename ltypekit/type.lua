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
local typeof = setmetatable({
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
    for rname, resolver in pairs(resolvers) do
      local val_type = resolver(val)
      if val_type then
        return val_type
      end
    end
    local val_type = type_(val)
    return val_type or false
  end,
  add_types = function(self, typel, resolver)
    table.insert(self.resolvers, resolver)
    for _index_0 = 1, #typel do
      local allowed = typel[_index_0]
      table.insert(self.types, allowed)
    end
  end,
  add = function(self, xtype, resolver)
    table.insert(self.resolvers, resolver)
    return table.insert(self.types, xtype)
  end,
  resolves = function(self, xtype)
    local _list_0 = self.types
    for _index_0 = 1, #_list_0 do
      local t = _list_0[_index_0]
      if xtype == t then
        return true
      end
    end
    return false
  end
}, {
  __call = function(self, val)
    return self.resolve(val, self.resolvers)
  end
})
local type = typeof
local typeforall
typeforall = function(t)
  local name = type(t[1])
  local status = true
  for _index_0 = 2, #t do
    local value = t[_index_0]
    if (typeof(value)) ~= name then
      status = false
      break
    end
  end
  if status then
    return name
  else
    return false
  end
end
return {
  type = type,
  typeof = typeof,
  typeforall = typeforall
}
