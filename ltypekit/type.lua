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
    has_meta = has_meta,
    is_io = is_io
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
  libraries = { },
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
  add_resolver = function(self, resolver)
    return table.insert(self.resolvers, resolver)
  end,
  add_allowed = function(self, allowed)
    return table.insert(self.types, allowed)
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
  export = function(self, xtype, resolver)
    return {
      resolver = self.resolvers[resolver],
      type = xtype
    }
  end,
  import = function(self, exported)
    table.insert(self.resolvers, exported.resolver)
    return table.insert(self.types, exported.type)
  end,
  set_library = function(self, xtype, lib)
    self.libraries[xtype] = lib
  end,
  libfor = function(self, xtype)
    return self.libraries[xtype]
  end,
  resolves = function(self, xtype)
    do
      local _with_0 = _(self.resolvers)
      _with_0:contains(xtype)
      return _with_0
    end
  end
}, {
  __call = function(self, val)
    return self.resolve(val, self.resolvers)
  end
})
local typeof = type
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
