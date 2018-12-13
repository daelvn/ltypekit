-- ltypekit | 23.11.2018
-- By daelvn
-- util functions
color = (require "ansicolors") or ((x) -> x\gsub "%b{}","")

warn  = (s) -> print color "%{yellow}[WARN]  #{s}"
panic = (s) -> print color "%{red}[ERROR] #{s}"
die   = (s) ->
  panic s
  error!

contains = (t, value) -> for val in *t do if val == value then return true

{:warn, :panic, :die, :contains}
