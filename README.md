# ltype
Advanced type checking library for Lua and Moonscript.
## ltype.type
This is a custom type checking function that supports custom types using resolvers. Similarly to [typical](https://github.com/hoelzro/lua-typical) or [mtype](https://github.com/jirutka/mtype), it first checks for a `__type` metavalue that will be returned (or called, if it is a function). Secondly, it checks whether the value is an io handle, and returns the "io" type if so. If there are no other resolvers, it will return the primitive type.
```moonscript
import type from require "ltype.type"

print type 5
--> number

xy_resolver = (any) ->
  if ((type any)    == "table") and
     ((type any[1]) == "number") and
     ((type any[2]) == "number") and
     (#any == 2)
    "position"
  else false
table.insert type.resolvers, xy_resolver

print type {5,6}
--> position
```
## ltype.init
This provides a way of attaching type signatures to functions, they can have the following formats:
```
number -> number -> number
  Equivalent to x -> (y -> z)
  Curried function. Unsafe mode will apply the right part (y -> z) to the function returned as a signature
number, number -> number
  Takes two arguments and returns another
number -> number, number
  Takes an argument and returns two
* -> string
  Takes any value, returns a string
! -> string
  Takes any value but nil, returns a string
x -> x
  Uses a placeholder (not registered in type.types)
  Input and output must be the same type
```
Usage:
```moonscript
import signature from "ltype"

add = (signature "number, number -> number") (a, b) -> a + b
print add 1, 1

add_curry = signature "number -> number -> number"
add_curry (a) -> (b) -> a + b
print  (add_curry 1, 2) 1 -- throws warning if .silent == false

add_curry_silent = with signature "number -> number -> number"
  .silent = true   -- Throws warnings
  .safe   = false  -- Warnings are not errors
add_curry_silent (a) -> (b) -> a + b
print dart (add_curry_silent 1) 1

tostring_ = with signature "* -> string"
  .silent = false
  .safe   = false
tostring_ (any) -> tostring any
print tostring_ nil
print tostring_ 2

position_resolver = (any) ->
  if ((type any)    == "table") and
     ((type any[1]) == "number") and
     ((type any[2]) == "number") and
     (#any == 2)
    "position"
  else false
position = signature "number, number -> position"
position - {"position"} + position_resolver
position (x, y) -> {x, y}
pos = position 3, 2
print pos

same_io = (signature "x -> y") (x) -> tonumber x
print same_io "5"
```
