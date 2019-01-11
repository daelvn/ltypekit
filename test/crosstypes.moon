import typeof from require "ltypekit.type"
import sign   from require "ltypekit.sign"

char_resolver = (v) -> if ((type v) == "string") and v\len! == 1 then "Char" else false
typeof\add "char", char_resolver

f = sign "Char -> Char"
f (c) ->
  print c
  c

f "a"
f "b"
