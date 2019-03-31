--> # ltypekit
--> Advanced type checking library for Lua
--> ## ltypekit/wrap
--> Wraps any function in a table so that it is able to hold properties.
import isTable, isCallable, typeof from require "ltypekit.7.type"

--> # wrap
--> Wraps a function in a table. It is possible to wrap tables which can be
--> called too, allowing for wrap recursion.
wrap = (f) ->
  error "wrap :: f is not callable, got '#{typeof f}'" unless isCallable f
  setmetatable { call: f }, { __call: f }

--> # unwrap
--> The opposite of `wrap`.
unwrap = (f) ->
  error "unwrap :: f is not callable, got '#{typeof f}'" unless isCallable f
  f.call if (isTable f) and f.call

--> # complexWrap
--> Lets you modify, sniff or check the arguments before calling the function.
complexWrap = (mod) ->
  error "complexWrap :: mod is not callable, got '#{typeof f}'" unless isCallable mod
  (f) ->
    error "complexWrap :: f is not callable, got '#{typeof f}'" unless isCallable f
    setmetatable { call: f }, { __call: mod f }

--> # sniff
--> Example modifier for `complexWrap`
sniff = (bindt) ->
  error "sniff :: bindt is not a table, got '#{typeof bindt}'" unless isTable bindt
  (f) ->
    error "sniff: f is not callable, got '#{typeof f}'" unless isCallable f
    (...) ->
      argl = {...}
      for i, arg in ipairs argl
        bindt[i] = arg
      f unpack argl

--> Return
{ :wrap, :unwrap, :complexWrap, :sniff }
