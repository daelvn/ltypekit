local binarize, compare
do
  local _obj_0 = require("ltypekit.signature")
  binarize, compare = _obj_0.binarize, _obj_0.compare
end
local type
type = require("ltypekit.type").type
local warn, die, contains
do
  local _obj_0 = require("ltypekit.util")
  warn, die, contains = _obj_0.warn, _obj_0.die, _obj_0.contains
end
local signature, callable
callable = function(f, sig, typef, safe, silent)
  return setmetatable({
    _type = typef,
    _signature = sig,
    _tree = binarize(sig),
    safe = safe,
    silent = silent
  }, {
    __type = "signed",
    __call = function(self, ...)
      local SIG = {
        signature = self._signature
      }
      local warn_ = warn
      warn = function(s)
        if safe then
          die(SIG, s)
        end
        if not silent then
          return warn_(s)
        end
      end
      local argn = #self._tree["in"]
      local argl = {
        ...
      }
      local arg_i = { }
      local holders = { }
      if #argl > argn then
        warn("There are more arguments than specified in the signature. Expected " .. tostring(argn) .. ", got " .. tostring(#argl))
      end
      for i = 1, argn do
        if self._tree["in"][i]:match("%->") then
          if (self._type(argl[i])) == "signed" then
            if argl[i]._signature == self._tree["in"][i] then
              table.insert(arg_i, argl[i])
            else
              if compare(argl[i]._signature, self._tree["in"][i], safe, silent) then
                table.insert(arg_i, argl[i])
              else
                die(SIG, "Wrong type for argument #" .. tostring(i) .. ". Expected (" .. tostring(self._tree["in"][i]) .. "), got (" .. tostring(argl[i]._signature) .. ")")
              end
            end
          else
            die(SIG, "Wrong type for argument #" .. tostring(i) .. ". Expected a signed function, got " .. tostring(self._type(argl[i])))
          end
        elseif self._tree["in"][i]:match("%*") then
          table.insert(arg_i, argl[i])
        elseif self._tree["in"][i]:match("%!") then
          if argl[i] ~= nil then
            table.insert(arg_i, argl[i])
          else
            die(SIG, "Wrong type for argument #" .. tostring(i) .. ". Expected any value, got nil")
          end
        elseif contains(self._type.types, self._tree["in"][i]) then
          if (self._type(argl[i])) == self._tree["in"][i] then
            table.insert(arg_i, argl[i])
          else
            die(SIG, "Wrong type for argument #" .. tostring(i) .. ". Expected " .. tostring(self._tree["in"][i]) .. ", got " .. tostring(self._type(argl[i])) .. ".")
          end
        else
          if holders[self._tree["in"][i]] then
            if (holders[self._tree["in"][i]] == self._type(argl[i])) then
              table.insert(arg_i, argl[i])
            else
              die(SIG, "Wrong type for argument #" .. tostring(i) .. ". Expected " .. tostring(holders[self._tree["in"][i]]) .. ", got " .. tostring(self._type(argl[i])))
            end
          else
            holders[self._tree["in"][i]] = self._type(argl[i])
            table.insert(arg_i, argl[i])
          end
        end
      end
      local arg_m = {
        f((unpack or table.unpack)(arg_i))
      }
      argn = #self._tree.out
      local arg_o = { }
      for i = 1, argn do
        if self._tree.out[i]:match("%->") then
          if (self._type(arg_m[i])) == "signed" then
            if arg_m[i]._signature == self._tree.out[i] then
              table.insert(arg_o, arg_m[i])
            else
              die(SIG, "Wrong type for return value #" .. tostring(i) .. ". Expected (" .. tostring(self._tree.out[i]) .. "), got (" .. tostring(arg_m[i]._signature) .. ")")
            end
          else
            if (self._type(arg_m[i])) == "function" then
              warn("Automatically signing right side. This might have unintended side consequences.")
              f = (signature(self._tree.out[i]))(arg_m[i])
              table.insert(arg_o, arg_m[i])
            else
              die(SIG, "Wrong type for return value #" .. tostring(i) .. ". Expected a signed function, got " .. tostring(self._type(arg_m[i])))
            end
          end
        elseif self._tree.out[i]:match("%*") then
          table.insert(arg_o, arg_m[i])
        elseif self._tree.out[i]:match("%!") then
          if arg_m[i] ~= nil then
            table.insert(arg_o, arg_m[i])
          else
            die(SIG, "Wrong type for return value #" .. tostring(i) .. ". Expected any value, got nil")
          end
        elseif contains(self._type.types, self._tree.out[i]) then
          if (self._type(arg_m[i])) == self._tree.out[i] then
            table.insert(arg_o, arg_m[i])
          else
            die(SIG, "Wrong type for return value #" .. tostring(i) .. ". Expected " .. tostring(self._tree.out[i]) .. ", got " .. tostring(self._type(arg_m[i])))
          end
        else
          if holders[self._tree.out[i]] then
            if (holders[self._tree.out[i]] == self._type(arg_m[i])) then
              table.insert(arg_o, arg_m[i])
            else
              die(SIG, "Wrong type for return value #" .. tostring(i) .. ". Expected " .. tostring(holders[self._tree.out[i]]) .. ", got " .. tostring(self._type(arg_m[i])))
            end
          else
            holders[self._tree.out[i]] = self._type(argl[i])
            table.insert(arg_o, arg_m[i])
          end
        end
      end
      return (unpack or table.unpack)(arg_o)
    end
  })
end
signature = function(sig)
  return setmetatable({
    _signature = sig,
    _type = type,
    safe = false,
    silent = true
  }, {
    __type = "signed_constructor",
    __add = function(self, resolver)
      table.insert(self._type.resolvers, resolver)
      return self
    end,
    __sub = function(self, typet)
      for _index_0 = 1, #typet do
        local type_ = typet[_index_0]
        table.insert(self._type.types, type_)
      end
      return self
    end,
    __call = function(self, f)
      return callable(f, self._signature, self._type, self.safe, self.silent)
    end
  })
end
return {
  signature = signature
}
