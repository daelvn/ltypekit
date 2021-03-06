-- ltypekit | 23.11.2018
-- By daelvn
-- util functions
color = (require "ansicolors") or ((x) -> x\gsub "%b{}","")

warn  = (s) -> print color "%{yellow}[WARN]  #{s}"
panic = (s) -> print color "%{red}[ERROR] #{s}"

traceback = (s) =>
  infot = {}
  for i=1,4 do infot[i] = debug.getinfo i
  print color "%{red}[ERROR] #{s}"
  print color "%{white}        In function: %{yellow}#{infot[3].name}%{white}"
  print color "        Signature:   %{green}'#{@signature or "???"}'"
  print color "        Stack traceback:"
  print color "          %{red}#{infot[1].name}%{white} in #{infot[1].source} at line #{infot[1].currentline}"
  print color "          %{red}#{infot[2].name}%{white} in #{infot[2].source} at line #{infot[2].currentline}"
  print color "          %{red}#{infot[3].name}%{white} in #{infot[3].source} at line #{infot[3].currentline}"
  print color "          %{red}#{infot[4].name}%{white} in #{infot[4].source} at line #{infot[4].currentline}"

die   = (s) =>
  traceback @, s
  error!

contains = (t, value) -> for val in *t do if val == value then return true

{:warn, :panic, :die, :contains}
