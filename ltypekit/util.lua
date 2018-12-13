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
local die
die = function(s)
  panic(s)
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
