local binarize, compare, rbinarize
do
  local _obj_0 = require("ltypekit.signature")
  binarize, compare, rbinarize = _obj_0.binarize, _obj_0.compare, _obj_0.rbinarize
end
local type
type = require("ltypekit.type").type
local warn, die, contains
do
  local _obj_0 = require("ltypekit.util")
  warn, die, contains = _obj_0.warn, _obj_0.die, _obj_0.contains
end
local sign
local apply_arguments
apply_arguments = function(self, argl)
  local SIG = {
    signature = self._signature
  }
  local parameters = { }
  local warn_ = warn
  warn = function(s)
    if self.safe then
      die(SIG, s)
    end
    if not self.silent then
      return warn_(s)
    end
  end
  local argn = #self._tree["in"]
  if #argl > argn then
    warn("There are more arguments than specified in the signature. Expected " .. tostring(argn) .. ", got " .. tostring(#argl))
  end
  local arg_i = { }
  for i = 1, argn do
    local matchable = ((self._type(self._tree["in"][i])) == "string") and true or false
    if matchable and self._tree["in"][i]:match("%->") then
      if (self._type(argl[i])) == "signed" then
        if argl[i]._signature == self._tree["in"][i] then
          table.insert(arg_i, argl[i])
        else
          if compare(argl[i]._signature, self._tree["in"][i], self.safe, self.silent) then
            table.insert(arg_i, argl[i])
          else
            die(SIG, "Wrong type for argument #" .. tostring(i) .. ". Expected (" .. tostring(self._tree["in"][i]) .. "), got (" .. tostring(argl[i]._signature) .. ")")
          end
        end
      else
        die(SIG, "Wrong type for argument #" .. tostring(i) .. ". Expected a signed function, got " .. tostring(self._type(argl[i])))
      end
    elseif matchable and self._tree["in"][i]:match("%*") then
      table.insert(arg_i, argl[i])
    elseif matchable and self._tree["in"][i]:match("%!") then
      if argl[i] ~= nil then
        local _ = arg_i, argl[i]
      else
        die(SIG, "Wrong type for argument #" .. tostring(i) .. ". Expected any value, got nil.")
      end
    elseif contains(self._type.types, self._tree["in"][i]) then
      if (self._type(argl[i])) == self._tree["in"][i] then
        table.insert(arg_i, argl[i])
      else
        die(SIG, "Wrong type for argument #" .. tostring(i) .. ". Expected " .. tostring(self._tree["in"][i]) .. ", got " .. tostring(self._type(argl[i])))
      end
    elseif ((self._type(self._tree["in"][i])) == "table") and (self._tree["in"][i][1] == 0) then
      local didset = false
      local _list_0 = self._tree["in"][i]
      for _index_0 = 2, #_list_0 do
        local type_ = _list_0[_index_0]
        if (self._type(argl[i])) == type_ then
          didset = true
        end
      end
      if didset then
        table.insert(arg_i, argl[i])
      else
        die(SIG, "Wrong type for argument #" .. tostring(i) .. ". Expected matching type in union, got " .. tostring(self._type(argl[i])))
      end
    elseif ((self._type(self._tree["in"][i])) == "table") and (self._tree["in"][i][1] == 1) then
      if parameters[self._tree["in"][i][2]] then
        local didset = false
        local _list_0 = parameters[self._tree["in"][i][2]]
        for _index_0 = 3, #_list_0 do
          local type_ = _list_0[_index_0]
          if (self._type(argl[i])) == type_ then
            didset = true
          end
        end
        if didset then
          table.insert(arg_i, argl[i])
        else
          die(SIG, "Wrong type for argument #" .. tostring(i) .. ". Expected matching type in generic, got " .. tostring(self._type(argl[i])))
        end
      else
        parameters[self._tree["in"][i][2]] = self._tree["in"][i]
        local didset = false
        local _list_0 = parameters[self._tree["in"][i][2]]
        for _index_0 = 3, #_list_0 do
          local type_ = _list_0[_index_0]
          if (self._type(argl[i])) == type_ then
            didset = true
          end
        end
        if didset then
          table.insert(arg_i, argl[i])
        else
          die(SIG, "Wrong type for argument #" .. tostring(i) .. ". Expected matching type in generic, got " .. tostring(self._type(argl[i])))
        end
      end
    else
      if parameters[self._tree["in"][i]] then
        if (parameters[self._tree["in"][i]] == self._type(argl[i])) then
          table.insert(arg_i, argl[i])
        else
          die(SIG, "Wrong type for argument #" .. tostring(i) .. ". Expected " .. tostring(parameters[self._tree["in"][i]]) .. ", got " .. tostring(self._type(argl[i])))
        end
      else
        parameters[self._tree["in"][i]] = self._type(argl[i])
        table.insert(arg_i, argl[i])
      end
    end
  end
  local arg_m = {
    self._function((unpack or table.unpack)(arg_i))
  }
  argn = #self._tree.out
  local arg_o = { }
  for i = 1, argn do
    local matchable = ((self._type(self._tree.out[i])) == "string") and true or false
    if matchable and self._tree.out[i]:match("%->") then
      if (self._type(arg_m[i])) == "signed" then
        if arg_m[i]._signature == self._tree.out[i] then
          table.insert(arg_o, arg_m[i])
        else
          if compare(arg_m[i]._signature, self._tree.out[i], self.safe, self.silent) then
            table.insert(arg_o, arg_m[i])
          else
            die(SIG, "Wrong type for return value #" .. tostring(i) .. ". Expected (" .. tostring(self._tree.out[i]) .. "), got (" .. tostring(arg_m[i]._signature) .. ")")
          end
        end
      elseif (self._type(arg_m[i])) == "function" then
        warn("Automatically signing right side. This might have unintended side consequences.")
        local f = (sign(self._tree.out[i]))(arg_m[i])
        table.insert(arg_o, arg_m[i])
      else
        die(SIG, "Wrong type for return value #" .. tostring(i) .. ". Expected a signed function, got " .. tostring(self._type(arg_m[i])))
      end
    elseif matchable and self._tree.out[i]:match("%*") then
      table.insert(arg_o, arg_m[i])
    elseif matchable and self._tree.out[i]:match("%!") then
      if arg_m[i] ~= nil then
        local _ = arg_o, arg_m[i]
      else
        die(SIG, "Wrong type for return value #" .. tostring(i) .. ". Expected any value, got nil.")
      end
    elseif contains(self._type.types, self._tree.out[i]) then
      if (self._type(arg_m[i])) == self._tree.out[i] then
        table.insert(arg_o, arg_m[i])
      else
        die(SIG, "Wrong type for return value #" .. tostring(i) .. ". Expected " .. tostring(self._tree.out[i]) .. ", got " .. tostring(self._type(arg_m[i])))
      end
    elseif ((self._type(self._tree.out[i])) == "table") and (self._tree.out[i][1] == 0) then
      local didset = false
      local _list_0 = self._tree.out[i]
      for _index_0 = 2, #_list_0 do
        local type_ = _list_0[_index_0]
        if (self._type(arg_m[i])) == type_ then
          didset = true
        end
      end
      if didset then
        table.insert(arg_o, arg_m[i])
      else
        die(SIG, "Wrong type for return value #" .. tostring(i) .. ". Expected matching type in union, got " .. tostring(self._type(arg_m[i])))
      end
    elseif ((self._type(self._tree.out[i])) == "table") and (self._tree.out[i][1] == 1) then
      if parameters[self._tree.out[i][2]] then
        local didset = false
        local _list_0 = parameters[self._tree.out[i][2]]
        for _index_0 = 3, #_list_0 do
          local type_ = _list_0[_index_0]
          if (self._type(arg_m[i])) == type_ then
            didset = true
          end
        end
        if didset then
          table.insert(arg_o, arg_m[i])
        else
          die(SIG, "Wrong type for return value #" .. tostring(i) .. ". Expected matching type in generic, got " .. tostring(self._type(arg_m[i])))
        end
      else
        parameters[self._tree.out[i][2]] = self._tree.out[i]
        local didset = false
        local _list_0 = parameters[self._tree.out[i][2]]
        for _index_0 = 3, #_list_0 do
          local type_ = _list_0[_index_0]
          if (self._type(arg_m[i])) == type_ then
            didset = true
          end
        end
        if didset then
          table.insert(arg_o, arg_m[i])
        else
          die(SIG, "Wrong type for return value #" .. tostring(i) .. ". Expected matching type in generic, got " .. tostring(self._type(arg_m[i])))
        end
      end
    else
      if parameters[self._tree.out[i]] then
        if (parameters[self._tree.out[i]] == self._type(arg_m[i])) then
          table.insert(arg_o, arg_m[i])
        else
          die(SIG, "Wrong type for return value #" .. tostring(i) .. ". Expected " .. tostring(parameters[self._tree.out[i]]) .. ", got " .. tostring(self._type(arg_m[i])))
        end
      else
        parameters[self._tree.out[i]] = self._type(arg_m[i])
        table.insert(arg_o, arg_m[i])
      end
    end
  end
  return (unpack or table.unpack)(arg_o)
end
sign = function(signature)
  return setmetatable({
    _signature = signature,
    _tree = rbinarize(signature),
    _type = type,
    _function = function() end,
    safe = false,
    silent = true
  }, {
    __type = "signed_constructor",
    __add = function(self, resolver)
      table.insert(self._type.resolvers, resolver)
      return self
    end,
    __sub = function(self, types)
      for _index_0 = 1, #types do
        local type_ = types[_index_0]
        table.insert(self._type.types, type_)
      end
      return self
    end,
    __call = function(self, ...)
      local argl = {
        ...
      }
      if (getmetatable(self)).__type == "signed_constructor" then
        self._function = argl[1];
        (getmetatable(self)).__type = "signed"
        return self
      end
      return apply_arguments(self, argl)
    end
  })
end
return {
  sign = sign
}
