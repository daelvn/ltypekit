local sign
sign = require("ltypekit.init").sign
local printi, dart
do
  local _obj_0 = require("ltext")
  printi, dart = _obj_0.printi, _obj_0.dart
end
local add = (sign("number, number -> number"))(function(a, b)
  return a + b
end)
print(dart(add(1, 1)))
local add_curry = sign("number -> number -> number")
add_curry(function(a)
  return function(b)
    return a + b
  end
end)
print(dart((add_curry(1, 2))(1)))
local add_curry_silent
do
  local _with_0 = sign("number -> number -> number")
  _with_0.silent = true
  _with_0.safe = false
  add_curry_silent = _with_0
end
add_curry_silent(function(a)
  return function(b)
    return a + b
  end
end)
print(dart((add_curry_silent(1))(1)))
local tostring_
do
  local _with_0 = sign("* -> string")
  _with_0.silent = false
  _with_0.safe = false
  tostring_ = _with_0
end
tostring_(function(any)
  return tostring(any)
end)
print(dart(tostring_(nil)))
print(dart(tostring_(2)))
local position_resolver
position_resolver = function(any)
  if ((type(any)) == "table") and ((type(any[1])) == "number") and ((type(any[2])) == "number") and (#any == 2) then
    return "position"
  else
    return false
  end
end
local position = sign("number, number -> position")
local _ = position - {
  "position"
} + position_resolver
position(function(x, y)
  return {
    x,
    y
  }
end)
local pos = position(3, 2)
printi(pos)
local same_io = (sign("x -> y"))(function(x)
  return tonumber(x)
end)
print(dart(same_io("5")))
local union = sign("[boolean|string] -> boolean")
union(function(x)
  if x == true then
    return true
  elseif x == false then
    return false
  else
    if x == "true" then
      return true
    elseif x == "false" then
      return false
    else
      return false
    end
  end
end)
print(dart(union(true)))
print(dart(union("false")))
print(dart(union("x")))
local generic = sign("x<boolean|string> -> x")
generic(function(x)
  if x == "x" then
    return 0
  else
    return x
  end
end)
print(dart(generic(true)))
return print(dart(generic("false")))
