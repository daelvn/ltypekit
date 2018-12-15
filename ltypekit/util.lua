local color = (require("ansicolors")) or (function(x)
  return x:gsub("%b{}", "")
end)
local warn
warn = function(s)
  return print(color("%{yellow}[WARN]  " .. tostring(s)))
end
local panic
panic = function(s)
  return print(color("%{red}[ERROR] " .. tostring(s)))
end
local traceback
traceback = function(self, s)
  local infot = { }
  for i = 1, 4 do
    infot[i] = debug.getinfo(i)
  end
  print(color("%{red}[ERROR] " .. tostring(s)))
  print(color("%{white}        In function: %{yellow}" .. tostring(infot[3].name) .. "%{white}"))
  print(color("        Signature:   %{green}'" .. tostring(self.signature or "???") .. "'"))
  print(color("        Stack traceback:"))
  print(color("          %{red}" .. tostring(infot[1].name) .. "%{white} in " .. tostring(infot[1].source) .. " at line " .. tostring(infot[1].currentline)))
  print(color("          %{red}" .. tostring(infot[2].name) .. "%{white} in " .. tostring(infot[2].source) .. " at line " .. tostring(infot[2].currentline)))
  print(color("          %{red}" .. tostring(infot[3].name) .. "%{white} in " .. tostring(infot[3].source) .. " at line " .. tostring(infot[3].currentline)))
  return print(color("          %{red}" .. tostring(infot[4].name) .. "%{white} in " .. tostring(infot[4].source) .. " at line " .. tostring(infot[4].currentline)))
end
local die
die = function(self, s)
  traceback(self, s)
  return error()
end
local contains
contains = function(t, value)
  for _index_0 = 1, #t do
    local val = t[_index_0]
    if val == value then
      return true
    end
  end
end
return {
  warn = warn,
  panic = panic,
  die = die,
  contains = contains
}
