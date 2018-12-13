import signature    from require "ltypekit.init"
import printi, dart from require "ltext"

add = (signature "number, number -> number") (a, b) -> a + b
print dart add 1, 1

add_curry = signature "number -> number -> number"
add_curry = add_curry (a) -> (b) -> a + b
print dart (add_curry 1, 2) 1

add_curry_silent = with signature "number -> number -> number"
  .silent = true
  .safe   = false
add_curry_silent = add_curry_silent (a) -> (b) -> a + b
print dart (add_curry_silent 1) 1

tostring_ = with signature "* -> string"
  .silent = false
  .safe   = false
tostring_ = tostring_ (any) -> tostring any
print dart tostring_ nil
print dart tostring_ 2

position_resolver = (any) ->
  if ((type any)    == "table") and
     ((type any[1]) == "number") and
     ((type any[2]) == "number") and
     (#any == 2)
    "position"
  else false
position = signature "number, number -> position"
position - {"position"} + position_resolver
position = position (x, y) -> {x, y}
pos = position 3, 2
printi pos

same_io = (signature "x -> y") (x) -> tonumber x
print dart same_io "5"

