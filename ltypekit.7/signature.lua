local inspect = require("inspect")
local insert
insert = function(t)
  return function(v)
    return table.insert(t, v)
  end
end
local prepare
prepare = function(sig)
  sig = sig:gsub(" %-> ", "->")
  sig = sig:gsub(" %=> ", "=>")
  return sig
end
local inspectStream
inspectStream = function(tokenStream)
  for _index_0 = 1, #tokenStream do
    local token = tokenStream[_index_0]
    print(token[1], token[2]:gsub(" ", "_"))
  end
end
local Ref
Ref = function(tag)
  if tag:match("%S") then
    return {
      "ref",
      tag
    }
  end
end
local Arrow = {
  "arr",
  "->"
}
local Constraint = {
  "con",
  "=>"
}
local Parenthesis
Parenthesis = function(tag)
  return {
    "par",
    tag
  }
end
local List
List = function(tag)
  return {
    "lst",
    tag
  }
end
local Separator
Separator = function(tag)
  return {
    "sep",
    tag
  }
end
local tokenize
tokenize = function(sig)
  local tokenStream = { }
  local intoStream = insert(tokenStream)
  local point = 0
  local await = false
  local cache = ""
  for char in (prepare(sig)):gmatch(".") do
    point = point + 1
    local _exp_0 = char
    if "(" == _exp_0 or ")" == _exp_0 then
      intoStream(Ref(cache))
      intoStream(Parenthesis(char))
      cache = ""
    elseif "[" == _exp_0 or "]" == _exp_0 then
      intoStream(Ref(cache))
      intoStream(List(char))
      cache = ""
    elseif "," == _exp_0 or " " == _exp_0 then
      intoStream(Ref(cache))
      intoStream(Separator(char))
      cache = ""
    elseif "-" == _exp_0 then
      intoStream(Ref(cache))
      await = "arrow"
      cache = ""
    elseif "=" == _exp_0 then
      intoStream(Ref(cache))
      await = "constraint"
      cache = ""
    elseif ">" == _exp_0 then
      local _exp_1 = await
      if "arrow" == _exp_1 then
        intoStream(Arrow)
      elseif "constraint" == _exp_1 then
        intoStream(Constraint)
      else
        error("tokenize :: Unexpected '>' at char " .. tostring(point))
      end
      await = false
    else
      cache = cache .. char
    end
  end
  return tokenStream
end
return inspectStream(tokenize("a -> (b -> c)"))
