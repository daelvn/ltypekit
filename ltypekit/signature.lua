local die, warn
do
  local _obj_0 = require("ltypekit.util")
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
  local udepth = false
  local in_cache = ""
  local out_cache = ""
  local u_cache = ""
  local union_cache = { }
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
  local uagglutinate
  uagglutinate = function(c)
    u_cache = u_cache .. c
  end
  local upush_cache
  upush_cache = function()
    table.insert(union_cache, u_cache)
    u_cache = ""
  end
  local upush_tree
  upush_tree = function()
    if right then
      table.insert(tree.out, union_cache)
      union_cache = { }
    else
      table.insert(tree["in"], union_cache)
      union_cache = { }
    end
  end
  local xagglutinate
  xagglutinate = function(c)
    if udepth then
      return uagglutinate(c)
    else
      return agglutinate(c)
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
      elseif "[" == _exp_0 then
        udepth = true
      elseif "]" == _exp_0 then
        if not udepth then
          die("binarize :: unmatching brackets (])")
        end
        upush_cache()
        upush_tree()
        udepth = false
      elseif "|" == _exp_0 then
        if not udepth then
          die("binarize :: OR (|) symbol used outside of union")
        end
        upush_cache()
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
        xagglutinate(char)
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
local printi
printi = require("ltext").printi
local rbinarize
rbinarize = function(sig)
  local tree = binarize(sig)
  for i = 1, #tree["in"] do
    if (type(tree["in"][i])) == "string" then
      if tree["in"][i]:match("%->") then
        tree["in"][i] = rbinarize(tree["in"][i])
      end
      if tree["in"][i] == "" then
        table.remove(tree["in"], i)
      end
    end
  end
  for i = 1, #tree.out do
    if (type(tree.out[i])) == "string" then
      if tree.out[i]:match("%->") then
        tree.out[i] = rbinarize(tree.out[i])
      end
      if tree.out[i] == "" then
        table.remove(tree.out, i)
      end
    end
  end
  return tree
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
  local is_t
  is_t = function(t)
    return (type(t)) == "table"
  end
  local is_s
  is_s = function(s)
    return (type(s)) == "string"
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
          if is_t(bsiga["in"][i]) then
            if is_s(bsigb["in"][i]) then
              local do_cont = false
              local _list_0 = bsiga["in"][i]
              for _index_0 = 1, #_list_0 do
                local type__ = _list_0[_index_0]
                if type__ == bsigb["in"][i] then
                  do_cont = true
                end
              end
              if do_cont then
                _continue_0 = true
                break
              else
                return false
              end
            elseif is_t(bsigb["in"][i]) then
              if bsiga["in"][i].out or bsigb["in"][i].out then
                return rcompare(bsiga["in"], bsigb["in"])
              end
              local do_cont = false
              local _list_0 = bsiga["in"][i]
              for _index_0 = 1, #_list_0 do
                local type__a = _list_0[_index_0]
                local _list_1 = bsigb["in"][i]
                for _index_1 = 1, #_list_1 do
                  local type__b = _list_1[_index_1]
                  if type__a == type__b then
                    do_cont = true
                  end
                end
              end
              if #bsiga["in"][i] ~= #bsigb["in"][i] then
                warn("comparing union type A (#" .. tostring(#bsiga["in"][i]) .. ") and B (#" .. tostring(bsigb["in"][i]) .. ")")
              end
              if do_cont then
                _continue_0 = true
                break
              else
                return false
              end
            end
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
          if is_t(bsiga.out[i]) then
            if is_s(bsigb.out[i]) then
              local do_cont = false
              local _list_0 = bsiga.out[i]
              for _index_0 = 1, #_list_0 do
                local type__ = _list_0[_index_0]
                if type__ == bsigb.out[i] then
                  do_cont = true
                end
              end
              if do_cont then
                _continue_0 = true
                break
              else
                return false
              end
            elseif is_t(bsigb.out[i]) then
              if bsiga.out[i].out or bsigb.out[i].out then
                return rcompare(bsiga.out, bsigb.out)
              end
              local do_cont = false
              local _list_0 = bsiga.out[i]
              for _index_0 = 1, #_list_0 do
                local type__a = _list_0[_index_0]
                local _list_1 = bsigb.out[i]
                for _index_1 = 1, #_list_1 do
                  local type__b = _list_1[_index_1]
                  if type__a == type__b then
                    do_cont = true
                  end
                end
              end
              if #bsiga.out[i] ~= #bsigb.out[i] then
                warn("comparing union type A (#" .. tostring(#bsiga.out[i]) .. ") and B (#" .. tostring(bsigb.out[i]) .. ")")
              end
            end
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
    return true
  end
  return rcompare(rbsiga, rbsigb)
end
return {
  binarize = binarize,
  rbinarize = rbinarize,
  compare = compare
}
