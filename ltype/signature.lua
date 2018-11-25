local die
die = require("ltype.util").die
local binarize
binarize = function(sig)
  local tree = {
    ["in"] = { },
    out = { }
  }
  local right = false
  local depth = 0
  local in_cache = ""
  local out_cache = ""
  local agglutinate
  agglutinate = function(c)
    if right then
      out_cache = out_cache .. c
    else
      in_cache = in_cache .. c
    end
  end
  local push_cache
  push_cache = function()
    if right then
      table.insert(tree.out, out_cache)
      out_cache = ""
    else
      table.insert(tree["in"], in_cache)
      in_cache = ""
    end
  end
  local symbol = false
  for char in sig:gmatch(".") do
    local _continue_0 = false
    repeat
      local _exp_0 = char
      if " " == _exp_0 then
        _continue_0 = true
        break
      elseif "(" == _exp_0 then
        depth = depth + 1
        agglutinate(char)
      elseif ")" == _exp_0 then
        depth = depth - 1
        agglutinate(char)
      elseif "-" == _exp_0 then
        if right then
          agglutinate(char)
        elseif depth == 0 then
          symbol = true
        else
          agglutinate(char)
        end
      elseif ">" == _exp_0 then
        if ((depth == 0) and not right) and not symbol then
          die("binarize :: unexpected character " .. tostring(char))
        end
        if right then
          agglutinate(char)
        elseif depth == 0 then
          push_cache()
          symbol = false
          right = true
        else
          agglutinate(char)
        end
      elseif "," == _exp_0 then
        if depth == 0 then
          push_cache()
        else
          agglutinate(char)
        end
      else
        agglutinate(char)
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  push_cache()
  if #tree.out < 1 then
    tree.out = tree["in"]
    tree["in"] = { }
  end
  for n, argument in ipairs(tree["in"]) do
    local _continue_0 = false
    repeat
      if (type(argument)) ~= "string" then
        _continue_0 = true
        break
      end
      if argument:match("%(.+%)") then
        tree["in"][n] = argument:sub(2, -2)
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  for n, argument in ipairs(tree.out) do
    local _continue_0 = false
    repeat
      if (type(argument)) ~= "string" then
        _continue_0 = true
        break
      end
      if argument:match("%(.+%)") then
        tree.out[n] = argument:sub(2, -2)
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  return tree
end
return {
  binarize = binarize
}
