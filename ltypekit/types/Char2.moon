--> # ltypekit/types/Char
--> `Char` type in Lua.
-- 07.02.2019
-- By daelvn
import sign                from require "ltypekit"
import typeof, data, typeE from require "ltypekit.type"

Char = {}
data Char,
  name:         "Char"
  annotation:   "Char string"
  resolver:     (v) -> ((type v)=="string") and (#v==1)
  constructor:  (v) -> v\sub 1,1
  constructors: {Char}
