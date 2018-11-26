-- ltypesign | 23.11.2018
-- By daelvn
-- Signature parsing
import die, warn from require "ltype.util"

binarize = (sig) ->
  tree      = in: {}, out: {}
  right     = false
  depth     = 0
  in_cache  = ""
  out_cache = ""

  agglutinate = (c) ->
    if right then out_cache ..= c
    else          in_cache  ..= c
  push_cache  = ->
    if right
      table.insert tree.out, out_cache
      out_cache = ""
    else
      table.insert tree.in, in_cache
      in_cache = ""

  -- symbol
  --  false: not started
  --  true:  started
  symbol = false
  for char in sig\gmatch "."
    switch char
      when " "
        continue
      when "("
        depth += 1
        agglutinate char
      when ")"
        depth -= 1
        agglutinate char
      when "-"
        if     right      then agglutinate char
        elseif depth == 0 then symbol = true
        else                   agglutinate char
      when ">"
        if ((depth == 0) and not right) and not symbol then die "binarize :: unexpected character #{char}"
        if     right then agglutinate char
        elseif depth == 0
          push_cache!
          symbol = false
          right  = true
        else agglutinate char
      when ","
        if depth == 0
          push_cache!
        else agglutinate char
      else
        agglutinate char
  push_cache!
  -- Fix signatures :: x -> (), which should be :: x
  if #tree.out < 1
    tree.out = tree.in
    tree.in  = {}
  -- Fix signatures :: (a -> b), which should be :: a -> b
  for n, argument in ipairs tree.in
    if (type argument) != "string" then continue
    if argument\match "%(.+%)"     then tree.in[n] = argument\sub 2, -2
  for n, argument in ipairs tree.out
    if (type argument) != "string" then continue
    if argument\match "%(.+%)"     then tree.out[n] = argument\sub 2, -2
  -- Return
  return tree

rbinarize = (sig) ->
  tree = binarize sig
  for i=1,#tree.in
    if tree.in[i]\match "%->" then tree.in[i] = rbinarize tree.in[i]
  for i=1,#tree.out
    if tree.out[i]\match "%->" then tree.in[i] = rbinarize tree.out[i]

compare = (siga, sigb, _safe, _silent) ->
  rbsiga = rbinarize siga
  rbsigb = rbinarize sigb

  warn_ = warn
  warn  = (s) ->
    if _safe       then die s
    if not _silent then warn_ s

  rcompare = (bsiga, bsigb)->
    if #bsiga.in  != #bsigb.in  then return false
    if #bsiga.out != #bsigb.out then return false
    for i=1,#bsiga.in
      if ((type bsiga.in[1]) == "table") and ((type bsigb.in[1]) == "table") then return rcompare bsiga.in, bsigb.in
      if     bsiga.in[i] == bsigb.in[i] then continue
      elseif bsiga.in[i] == "*"         then continue
      elseif bsigb.in[i] == "*"         then continue
      elseif bsiga.in[i] == "!"
        if bsigb.in[i] == "*" then warn "comparing (#{siga}) and (#{sigb}). signature B might take nil"
        continue
      elseif bsigb.in[i] == "!"
        if bsiga.in[i] == "*" then warn "comparing (#{siga}) and (#{sigb}). signature A might take nil"
        continue
      return false
    for i=1,#bsiga.out
      if ((type bsiga.out[1]) == "table") and ((type bsigb.out[1]) == "table") then return rcompare bsiga.out, bsigb.out
      if     bsiga.out[i] == bsigb.out[i] then continue
      elseif bsiga.out[i] == "*"         then continue
      elseif bsigb.out[i] == "*"         then continue
      elseif bsiga.out[i] == "!"
        if bsigb.out[i] == "*" then warn "comparing (#{siga}) and (#{sigb}). signature B might return nil"
        continue
      elseif bsigb.out[i] == "!"
        if bsiga.out[i] == "*" then warn "comparing (#{siga}) and (#{sigb}). signature A might return nil"
        continue
      return false
    
  rcompare rbsiga, rbsigb

{:binarize, :rbinarize, :compare}
