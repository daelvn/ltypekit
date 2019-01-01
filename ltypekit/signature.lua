local die, warn
do
  local _obj_0 = require("ltypekit.util")
  die, warn = _obj_0.die, _obj_0.warn
end
local is_union
is_union = function(u)
  if (type(u)) ~= "table" then
    local _ = false
  end
  if (u[1] == 0) and ((type(u[2])) == "string") and ((type(u[3])) == "string") then
    return true
  else
    return false
  end
end
local is_constraint
is_constraint = function(g)
  if (type(g)) ~= "table" then
    local _ = false
  end
  if (g[1] == 1) and ((type(g[2])) == "string") and ((type(g[3])) == "string") then
    return true
  else
    return false
  end
end
local binarize
binarize = function(sig)
  sig = sig:gsub("%?", "|nil")
  sig = sig:gsub("/", "[function|signed]")
  local SIG = {
    signature = sig
  }
  local tree = {
    ["in"] = { },
    out = { }
  }
  local right = false
  local depth = {
    general = 0,
    union = 0,
    constraint = 0
  }
  local _stack = { }
  local stack = {
    push = function(x)
      return table.insert(_stack, 1, x)
    end,
    pop = function()
      return table.remove(_stack, 1)
    end,
    peek = function()
      return _stack[1]
    end
  }
  local cache = {
    ["in"] = "",
    out = "",
    iunion = "",
    iconstraint = "",
    union = {
      0
    },
    constraint = {
      1
    },
    empty = { }
  }
  cache.current = function()
    if right then
      return cache.out
    else
      return cache["in"]
    end
  end
  cache.empty.io = function()
    if right then
      cache.out = ""
    else
      cache["in"] = ""
    end
  end
  local lookbehind = { }
  local agglutinate = {
    io = function(c)
      if right then
        cache.out = cache.out .. c
      else
        cache["in"] = cache["in"] .. c
      end
    end,
    union = function(c)
      cache.iunion = cache.iunion .. c
    end,
    constraint = function(c)
      cache.iconstraint = cache.iconstraint .. c
    end
  }
  local attach = {
    union = function()
      table.insert(cache.union, cache.iunion)
      cache.iunion = ""
    end,
    constraint = function()
      table.insert(cache.constraint, cache.iconstraint)
      cache.iconstraint = ""
    end
  }
  local push = {
    io = function()
      if right then
        table.insert(tree.out, cache.out)
        cache.out = ""
      else
        table.insert(tree["in"], cache["in"])
        cache["in"] = ""
      end
    end,
    union = function()
      if right then
        table.insert(tree.out, cache.union)
        cache.union = {
          0
        }
      else
        table.insert(tree["in"], cache.union)
        cache.union = {
          0
        }
      end
    end,
    constraint = function()
      if right then
        table.insert(tree.out, cache.constraint)
        cache.constraint = {
          1
        }
      else
        table.insert(tree["in"], cache.constraint)
        cache.constraint = {
          1
        }
      end
    end
  }
  attach["or"] = function()
    if stack.peek() == "[" then
      return attach.union()
    elseif stack.peek() == "{" then
      return attach.constraint()
    else
      return die(SIG, "binarize $ attempt to use '|' at unknown point.")
    end
  end
  agglutinate.x = function(c)
    if stack.peek() == "[" then
      return agglutinate.union(c)
    elseif stack.peek() == "{" then
      return agglutinate.constraint(c)
    else
      return agglutinate.io(c)
    end
  end
  local count = 1
  for char in sig:gmatch(".") do
    local _continue_0 = false
    repeat
      local _exp_0 = char
      if " " == _exp_0 then
        _continue_0 = true
        break
      elseif "(" == _exp_0 then
        depth.general = depth.general + 1
        stack.push("(")
        agglutinate.io(char)
      elseif ")" == _exp_0 then
        if stack.peek() ~= "(" then
          die(SIG, "binarize $ unmatching parenthesis () (index: " .. tostring(count) .. ")")
        end
        stack.pop()
        depth.general = depth.general - 1
        agglutinate.io(char)
      elseif "[" == _exp_0 then
        if right then
          agglutinate.io(char)
        elseif depth.general == 0 then
          depth.union = depth.union + 1
          stack.push("[")
        else
          agglutinate.io(char)
        end
      elseif "]" == _exp_0 then
        if right then
          agglutinate.io(char)
        elseif depth.general == 0 then
          if stack.peek() ~= "[" then
            die(SIG, "binarize $ unmatching square brackets [] (index: " .. tostring(count) .. ")")
          end
          stack.pop()
          depth.union = depth.union - 1
          attach.union()
          push.union()
        else
          agglutinate.io(char)
        end
      elseif "{" == _exp_0 then
        if right then
          agglutinate.io(char)
        elseif depth.general == 0 then
          depth.constraint = depth.constraint + 1
          stack.push("{")
          agglutinate.constraint(cache.current())
          cache.empty.io()
          attach.constraint()
        else
          agglutinate.io(char)
        end
      elseif "}" == _exp_0 then
        if right then
          agglutinate.io(char)
        elseif depth.general == 0 then
          if stack.peek() ~= "{" then
            die(SIG, "binarize $ unmatching curly brackets {} (index: " .. tostring(count) .. ")")
          end
          stack.pop()
          depth.constraint = depth.constraint - 1
          attach.constraint()
          push.constraint()
        end
      elseif "-" == _exp_0 then
        if right then
          agglutinate.io(char)
        elseif depth.general == 0 then
          local symbol = true
        else
          agglutinate.io(char)
        end
      elseif ">" == _exp_0 then
        if (lookbehind[count - 1] == "-") then
          if right then
            agglutinate.io(char)
          elseif depth.general == 0 then
            push.io()
            right = true
          else
            agglutinate.io(char)
          end
        else
          die(SIG, "binarize $ unexpected character '-'")
        end
      elseif "|" == _exp_0 then
        if right then
          agglutinate.io(char)
        elseif depth.general == 0 then
          attach["or"]()
        else
          agglutinate.io(char)
        end
      elseif "," == _exp_0 then
        if depth.general == 0 then
          push.io()
        else
          agglutinate.io(char)
        end
      else
        agglutinate.x(char)
      end
      count = count + 1
      table.insert(lookbehind, char)
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  push.io()
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
  if (#tree.out == 1) and not (tree.out[1]:match("%->")) and (tree.out[1]:match("[%[<>%]]")) then
    tree.out[1] = (binarize(tree.out[1])).out[1]
  end
  local remove_empty
  remove_empty = function(t)
    for k, v in pairs(t) do
      if (type(v)) == "table" then
        t[k] = remove_empty(v)
      else
        if v == "" then
          table.remove(t, k)
        end
      end
    end
    return t
  end
  remove_empty(tree["in"])
  remove_empty(tree.out)
  local assign_constraints
  assign_constraints = function(t, known)
    if known == nil then
      known = { }
    end
    for k, v in pairs(t) do
      local _continue_0 = false
      repeat
        if (type(v)) == "table" then
          if v[1] == 1 then
            known[v[2]] = v
          else
            t[k] = assign_constraints(v, known)
          end
        elseif (type(v)) == "string" then
          if known[v] then
            t[k] = known[v]
          end
        else
          _continue_0 = true
          break
        end
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    return t
  end
  assign_constraints(tree)
  return tree
end
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
compare = function(a, b, _safe, _silent)
  local SIG = {
    signature = tostring(a) .. "; " .. tostring(b)
  }
  local ra = rbinarize(a)
  local rb = rbinarize(b)
  local warn_ = warn
  warn = function(s)
    if _safe then
      die(SIG, s)
    end
    if not _silent then
      return warn_(s)
    end
  end
  local is_string
  is_string = function(s)
    return (type(s)) == "string"
  end
  local is_table
  is_table = function(t)
    return (type(t)) == "table"
  end
  local is_number
  is_number = function(n)
    return (type(n)) == "number"
  end
  local rcompare
  rcompare = function(ta, tb)
    if #ta["in"] ~= #tb["in"] then
      local _ = false
    end
    if #ta.out ~= #tb.out then
      local _ = false
    end
    for i = 1, #ta["in"] do
      local _continue_0 = false
      repeat
        if is_table(ta["in"][i]) then
          if is_table(tb["in"][i]) then
            local xa = ta["in"][i]
            local xb = tb["in"][i]
            if xa[1] == 0 then
              local common = 0
              local notcommon = 0
              local didset = false
              for _index_0 = 2, #xa do
                local atype = xa[_index_0]
                for _index_1 = 2, #xb do
                  local btype = xb[_index_1]
                  if atype == btype then
                    common = common + 1
                    didset = true
                  end
                end
                if didset then
                  didset = false
                else
                  notcommon = notcommon + 1
                end
              end
              if notcommon > 0 then
                warn("comparing union (#" .. tostring(xa) .. ") and (#" .. tostring(xb) .. "}, there are " .. tostring(notcommon) .. " unmatching types")
              end
              if common == 0 then
                return false
              end
              _continue_0 = true
              break
            elseif xa[1] == 1 then
              local common = 0
              local notcommon = 0
              local didset = false
              for _index_0 = 3, #xa do
                local atype = xa[_index_0]
                for _index_1 = 3, #xa do
                  local btype = xa[_index_1]
                  if atype == btype then
                    common = common + 1
                    didset = true
                  end
                end
                if didset then
                  didset = false
                else
                  notcommon = notcommon + 1
                end
              end
              if notcommon > 0 then
                warn("1:" .. tostring(common) .. " comparing constraint (#" .. tostring(xa) .. ") and (#" .. tostring(xb) .. "), there are " .. tostring(notcommon) .. " unmatching types")
              end
              if common == 0 then
                return false
              end
              _continue_0 = true
              break
            else
              rcompare(xa, xb)
            end
          elseif is_string(tb["in"][i]) then
            local xa = ta["in"][i]
            local xb = tb["in"][i]
            if xa[1] == 0 then
              local common = 0
              local notcommon = 0
              local didset = false
              for _index_0 = 2, #xa do
                local atype = xa[_index_0]
                if atype == xb then
                  common = common + 1
                  didset = true
                end
                if didset then
                  didset = false
                else
                  notcommon = notcommon + 1
                end
              end
              if notcommon > 0 then
                warn("comparing union (#" .. tostring(xa) .. ") and (#" .. tostring(xb) .. "}, there are " .. tostring(notcommon) .. " unmatching types")
              end
              if common == 0 then
                return false
              end
              _continue_0 = true
              break
            elseif xa[1] == 1 then
              local common = 0
              local notcommon = 0
              local didset = false
              for _index_0 = 3, #xa do
                local atype = xa[_index_0]
                if atype == xb then
                  common = common + 1
                  didset = true
                end
                if didset then
                  didset = false
                else
                  notcommon = notcommon + 1
                end
              end
              if notcommon > 0 then
                warn("2:" .. tostring(common) .. " comparing constraint (#" .. tostring(xa) .. ") and (#" .. tostring(xb) .. "}, there are " .. tostring(notcommon) .. " unmatching types")
              end
              if common == 0 then
                return false
              end
              _continue_0 = true
              break
            else
              return false
            end
          elseif is_number(tb["in"][i]) then
            die(SIG, "compare $ Impossible error I")
          else
            die(SIG, "compare $ Impossible error II")
          end
        elseif is_string(ta["in"][i]) then
          if is_table(tb["in"][i]) then
            local xa = ta["in"][i]
            local xb = tb["in"][i]
            if xb[1] == 0 then
              local common = 0
              local notcommon = 0
              local didset = false
              for _index_0 = 2, #xb do
                local atype = xb[_index_0]
                if atype == xa then
                  common = common + 1
                  didset = true
                end
                if didset then
                  didset = false
                else
                  notcommon = notcommon + 1
                end
              end
              if notcommon > 0 then
                warn("comparing union (#" .. tostring(xa) .. ") and (#" .. tostring(xb) .. "}, there are " .. tostring(notcommon) .. " unmatching types")
              end
              if common == 0 then
                return false
              end
              _continue_0 = true
              break
            elseif xb[1] == 1 then
              local common = 0
              local notcommon = 0
              local didset = false
              for _index_0 = 3, #xb do
                local atype = xb[_index_0]
                if atype == xa then
                  common = common + 1
                  didset = true
                end
                if didset then
                  didset = false
                else
                  notcommon = notcommon + 1
                end
              end
              if notcommon > 0 then
                warn("3:" .. tostring(common) .. " comparing constraint (#" .. tostring(xa) .. ") and (#" .. tostring(xb) .. "}, there are " .. tostring(notcommon) .. " unmatching types")
              end
              if common == 0 then
                return false
              end
              _continue_0 = true
              break
            else
              return false
            end
          elseif is_string(tb["in"][i]) then
            local xa = ta["in"][i]
            local xb = tb["in"][i]
            if xa == xb then
              _continue_0 = true
              break
            elseif (xa == "*") and (xb == "!") then
              warn("comparing A:(" .. tostring(a) .. ") and B:(" .. tostring(b) .. "). A might take nil.")
            elseif (xa == "!") and (xb == "!") then
              warn("comparing A:(" .. tostring(a) .. ") and B:(" .. tostring(b) .. "). B might take nil.")
            else
              return false
            end
          else
            die(SIG, "compare $ Impossible error III")
          end
        else
          die(SIG, "compare $ Impossible error IV")
        end
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    for i = 1, #ta.out do
      local _continue_0 = false
      repeat
        if is_table(ta.out[i]) then
          if is_table(tb.out[i]) then
            local xa = ta.out[i]
            local xb = tb.out[i]
            if xa[1] == 0 then
              local common = 0
              local notcommon = 0
              local didset = false
              for _index_0 = 2, #xa do
                local atype = xa[_index_0]
                for _index_1 = 2, #xb do
                  local btype = xb[_index_1]
                  if atype == btype then
                    common = common + 1
                    didset = false
                  end
                end
                if didset then
                  didset = false
                else
                  notcommon = notcommon + 1
                end
              end
              if notcommon > 0 then
                warn("comparing union (#" .. tostring(xa) .. ") and (#" .. tostring(xb) .. "}, there are " .. tostring(notcommon) .. " unmatching types")
              end
              if common == 0 then
                return false
              end
              _continue_0 = true
              break
            elseif xa[1] == 1 then
              local common = 0
              local notcommon = 0
              local didset = false
              for _index_0 = 3, #xa do
                local atype = xa[_index_0]
                for _index_1 = 3, #xa do
                  local btype = xa[_index_1]
                  if atype == btype then
                    common = common + 1
                    didset = true
                  end
                end
                if didset then
                  didset = false
                else
                  notcommon = notcommon + 1
                end
              end
              if notcommon > 0 then
                warn("4:" .. tostring(common) .. " comparing constraint (#" .. tostring(xa) .. ") and (#" .. tostring(xb) .. "), there are " .. tostring(notcommon) .. " unmatching types")
              end
              if common == 0 then
                return false
              end
              _continue_0 = true
              break
            else
              rcompare(xa, xb)
            end
          elseif is_string(tb.out[i]) then
            local xa = ta.out[i]
            local xb = tb.out[i]
            if xa[1] == 0 then
              local common = 0
              local notcommon = 0
              local didset = false
              for _index_0 = 2, #xa do
                local atype = xa[_index_0]
                if atype == xb then
                  common = common + 1
                  didset = true
                end
                if didset then
                  didset = false
                else
                  notcommon = notcommon + 1
                end
              end
              if notcommon > 0 then
                warn("comparing union (#" .. tostring(xa) .. ") and (#" .. tostring(xb) .. "}, there are " .. tostring(notcommon) .. " unmatching types")
              end
              if common == 0 then
                return false
              end
              _continue_0 = true
              break
            elseif xa[1] == 1 then
              local common = 0
              local notcommon = 0
              local didset = false
              for _index_0 = 3, #xa do
                local atype = xa[_index_0]
                if atype == xb then
                  common = common + 1
                  didset = true
                end
                if didset then
                  didset = false
                else
                  notcommon = notcommon + 1
                end
              end
              if notcommon > 0 then
                warn("5:" .. tostring(common) .. " comparing constraint (#" .. tostring(xa) .. ") and (#" .. tostring(xb) .. "}, there are " .. tostring(notcommon) .. " unmatching types")
              end
              if common == 0 then
                return false
              end
              _continue_0 = true
              break
            else
              return false
            end
          elseif is_number(tb.out[i]) then
            die(SIG, "compare $ Impossible error I")
          else
            die(SIG, "compare $ Impossible error II")
          end
        elseif is_string(ta.out[i]) then
          if is_table(tb.out[i]) then
            local xa = ta.out[i]
            local xb = tb.out[i]
            if xb[1] == 0 then
              local common = 0
              local notcommon = 0
              local didset = false
              for _index_0 = 2, #xb do
                local atype = xb[_index_0]
                if atype == xa then
                  common = common + 1
                  didset = true
                end
                if didset then
                  didset = false
                else
                  notcommon = notcommon + 1
                end
              end
              if notcommon > 0 then
                warn("comparing union (#" .. tostring(xa) .. ") and (#" .. tostring(xb) .. "}, there are " .. tostring(notcommon) .. " unmatching types")
              end
              if common == 0 then
                return false
              end
              _continue_0 = true
              break
            elseif xb[1] == 1 then
              local common = 0
              local notcommon = 0
              local didset = false
              for _index_0 = 3, #xb do
                local atype = xb[_index_0]
                if atype == xa then
                  common = common + 1
                  didset = true
                end
                if didset then
                  didset = false
                else
                  notcommon = notcommon + 1
                end
              end
              if notcommon > 0 then
                warn("6:" .. tostring(common) .. " comparing constraint (#" .. tostring(xa) .. ") and (#" .. tostring(xb) .. "}, there are " .. tostring(notcommon) .. " unmatching types")
              end
              if common == 0 then
                return false
              end
              _continue_0 = true
              break
            else
              return false
            end
          elseif is_string(tb.out[i]) then
            local xa = ta.out[i]
            local xb = tb.out[i]
            if xa == xb then
              _continue_0 = true
              break
            elseif (xa == "*") and (xb == "!") then
              warn("comparing A:(" .. tostring(a) .. ") and B:(" .. tostring(b) .. "). A might take nil.")
            elseif (xa == "!") and (xb == "!") then
              warn("comparing A:(" .. tostring(a) .. ") and B:(" .. tostring(b) .. "). B might take nil.")
            else
              return false
            end
          else
            die(SIG, "compare $ Impossible error III")
          end
        else
          die(SIG, "compare $ Impossible error IV")
        end
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    return true
  end
  return rcompare(ra, rb)
end
return {
  is_union = is_union,
  is_constraint = is_constraint,
  binarize = binarize,
  rbinarize = rbinarize,
  compare = compare
}
