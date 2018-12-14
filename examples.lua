local signature
signature = require("ltypekit.init").signature
local printi, dart
do
  local _obj_0 = require("ltext")
  printi, dart = _obj_0.printi, _obj_0.dart
end
local add = (signature("number, number -> number"))(function(a, b)
  return a + b
end)
printi(add)
print(dart(add(1, 1)))
local add_curry = signature("number -> number -> number")
add_curry(function(a)
  return function(b)
    return a + b
  end
end)
print(dart((add_curry(1, 2))(1)))
local add_curry_silent
do
  local _with_0 = signature("number -> number -> number")
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
  local _with_0 = signature("* -> string")
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
local position = signature("number, number -> position")
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
local same_io = (signature("x -> y"))(function(x)
  return tonumber(x)
end)
return print(dart(same_io("5")))
