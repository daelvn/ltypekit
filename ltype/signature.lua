local die, warn
do
  local _obj_0 = require("ltype.util")
  die, warn = _obj_0.die, _obj_0.warn
end
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
local rbinarize
rbinarize = function(sig)
  local tree = binarize(sig)
  for i = 1, #tree["in"] do
    if tree["in"][i]:match("%->") then
      tree["in"][i] = rbinarize(tree["in"][i])
    end
  end
  for i = 1, #tree.out do
    if tree.out[i]:match("%->") then
      tree["in"][i] = rbinarize(tree.out[i])
    end
  end
end
local compare
compare = function(siga, sigb, _safe, _silent)
  local rbsiga = rbinarize(siga)
  local rbsigb = rbinarize(sigb)
  local warn_ = warn
  warn = function(s)
    if _safe then
      die(s)
    end
    if not _silent then
      return warn_(s)
    end
  end
  local rcompare
  rcompare = function(bsiga, bsigb)
    if #bsiga["in"] ~= #bsigb["in"] then
      return false
    end
    if #bsiga.out ~= #bsigb.out then
      return false
    end
    for i = 1, #bsiga["in"] do
      local _continue_0 = false
      repeat
        do
          if ((type(bsiga["in"][1])) == "table") and ((type(bsigb["in"][1])) == "table") then
            return rcompare(bsiga["in"], bsigb["in"])
          end
          if bsiga["in"][i] == bsigb["in"][i] then
            _continue_0 = true
            break
          elseif bsiga["in"][i] == "*" then
            _continue_0 = true
            break
          elseif bsigb["in"][i] == "*" then
            _continue_0 = true
            break
          elseif bsiga["in"][i] == "!" then
            if bsigb["in"][i] == "*" then
              warn("comparing (" .. tostring(siga) .. ") and (" .. tostring(sigb) .. "). signature B might take nil")
            end
            _continue_0 = true
            break
          elseif bsigb["in"][i] == "!" then
            if bsiga["in"][i] == "*" then
              warn("comparing (" .. tostring(siga) .. ") and (" .. tostring(sigb) .. "). signature A might take nil")
            end
            _continue_0 = true
            break
          end
          return false
        end
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    for i = 1, #bsiga.out do
      local _continue_0 = false
      repeat
        do
          if ((type(bsiga.out[1])) == "table") and ((type(bsigb.out[1])) == "table") then
            return rcompare(bsiga.out, bsigb.out)
          end
          if bsiga.out[i] == bsigb.out[i] then
            _continue_0 = true
            break
          elseif bsiga.out[i] == "*" then
            _continue_0 = true
            break
          elseif bsigb.out[i] == "*" then
            _continue_0 = true
            break
          elseif bsiga.out[i] == "!" then
            if bsigb.out[i] == "*" then
              warn("comparing (" .. tostring(siga) .. ") and (" .. tostring(sigb) .. "). signature B might return nil")
            end
            _continue_0 = true
            break
          elseif bsigb.out[i] == "!" then
            if bsiga.out[i] == "*" then
              warn("comparing (" .. tostring(siga) .. ") and (" .. tostring(sigb) .. "). signature A might return nil")
            end
            _continue_0 = true
            break
          end
          return false
        end
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
  end
  return rcompare(rbsiga, rbsigb)
end
return {
  binarize = binarize,
  rbinarize = rbinarize,
  compare = compare
}
