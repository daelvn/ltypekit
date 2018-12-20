import sign         from require "ltypekit.init"
import printi, dart from require "ltext"

add = (sign "number, number -> number") (a, b) -> a + b
print dart add 1, 1

add_curry = sign "number -> number -> number"
add_curry (a) -> (b) -> a + b
print dart (add_curry 1, 2) 1

add_curry_silent = with sign "number -> number -> number"
  .silent = true
  .safe   = false
add_curry_silent (a) -> (b) -> a + b
print dart (add_curry_silent 1) 1

tostring_ = with sign "* -> string"
  .silent = false
  .safe   = false
tostring_ (any) -> tostring any
print dart tostring_ nil
print dart tostring_ 2

position_resolver = (any) ->
  if ((type any)    == "table") and
     ((type any[1]) == "number") and
     ((type any[2]) == "number") and
     (#any == 2)
    "position"
  else false
position = sign "number, number -> position"
position - {"position"} + position_resolver
position (x, y) -> {x, y}
pos = position 3, 2
printi pos

same_io = (sign "x -> y") (x) -> tonumber x
print dart same_io "5"

union = sign "[boolean|string] -> boolean"
union (x) ->
  if     x == true  then return true
  elseif x == false then return false
  else
    return if x == "true"
      true
    elseif x == "false"
      false
    else
      false

print dart union true
print dart union "false"
print dart union "x"
--print dart union 0

generic = sign "x<boolean|string> -> x"
generic (x) -> if x == "x" then 0 else x

print dart generic true
print dart generic "false"
--print dart generic "x"
