-- ltypekitsign | 23.11.2018
-- By daelvn
-- Signature parsing
import die, warn from require "ltypekit.util"

binarize = (sig) ->
  SIG       = {signature: sig}
  tree      = in: {}, out: {}
  right     = false
  depth     = 0
  udepth    = false
  in_cache  = ""
  out_cache = ""

  u_cache     = ""
  union_cache = {}

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

  uagglutinate = (c) -> u_cache ..= c
  upush_cache = ->
    table.insert union_cache, u_cache
    u_cache = ""
  upush_tree = ->
    if right
      table.insert tree.out, union_cache
      union_cache = {}
    else
      table.insert tree.in, union_cache
      union_cache = {}
    

  xagglutinate = (c) ->
    if udepth then uagglutinate c
    else           agglutinate c

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
      when "["
        udepth = true
      when "]"
        if not udepth then die SIG, "binarize :: unmatching brackets (])"
        upush_cache!
        upush_tree!
        udepth = false
      when "|"
        if not udepth then die SIG, "binarize :: OR (|) symbol used outside of union"
        upush_cache!
      when "-"
        if     right      then agglutinate char
        elseif depth == 0 then symbol = true
        else                   agglutinate char
      when ">"
        if ((depth == 0) and not right) and not symbol then die SIG, "binarize :: unexpected character #{char}"
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
        xagglutinate char
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

import printi from require "ltext"

rbinarize = (sig) ->
  tree = binarize sig
  for i=1,#tree.in
    if (type tree.in[i]) == "string"
      if tree.in[i]\match "%->" then tree.in[i] = rbinarize tree.in[i]
      if tree.in[i] == ""       then table.remove tree.in, i
  for i=1,#tree.out
    if (type tree.out[i]) == "string"
      if tree.out[i]\match "%->" then tree.out[i] = rbinarize tree.out[i]
      if tree.out[i] == ""       then table.remove tree.out, i
  tree

compare = (siga, sigb, _safe, _silent) ->
  rbsiga = rbinarize siga
  rbsigb = rbinarize sigb

  warn_ = warn
  warn  = (s) ->
    if _safe       then die SIG, s
    if not _silent then warn_ s

  is_t = (t) -> (type t) == "table"
  is_s = (s) -> (type s) == "string"

  rcompare = (bsiga, bsigb)->
    if #bsiga.in  != #bsigb.in  then return false
    if #bsiga.out != #bsigb.out then return false
    for i=1,#bsiga.in
      if is_t bsiga.in[i]
        if is_s bsigb.in[i] -- [.|...] ? .
          do_cont = false
          for type__ in *bsiga.in[i]
            if type__ == bsigb.in[i] then do_cont = true
          if do_cont then continue else return false
        elseif is_t bsigb.in[i] -- [.|...] ? [.|...] OR rcompare
          if bsiga.in[i].out or bsigb.in[i].out then return rcompare bsiga.in, bsigb.in
          do_cont = false
          for type__a in *bsiga.in[i]
            for type__b in *bsigb.in[i]
              if type__a == type__b then do_cont = true
          if #bsiga.in[i] != #bsigb.in[i] then warn "comparing union type A (##{#bsiga.in[i]}) and B (##{bsigb.in[i]})"
          if do_cont then continue else return false
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
      if is_t bsiga.out[i]
        if is_s bsigb.out[i] -- [.|...] ? .
          do_cont = false
          for type__ in *bsiga.out[i]
            if type__ == bsigb.out[i] then do_cont = true
          if do_cont then continue else return false
        elseif is_t bsigb.out[i] -- [.|...] ? [.|...] OR rcompare
          if bsiga.out[i].out or bsigb.out[i].out then return rcompare bsiga.out, bsigb.out
          do_cont = false
          for type__a in *bsiga.out[i]
            for type__b in *bsigb.out[i]
              if type__a == type__b then do_cont = true
          if #bsiga.out[i] != #bsigb.out[i] then warn "comparing union type A (##{#bsiga.out[i]}) and B (##{bsigb.out[i]})"
      if     bsiga.out[i] == bsigb.out[i] then continue
      elseif bsiga.out[i] == "*"          then continue
      elseif bsigb.out[i] == "*"          then continue
      elseif bsiga.out[i] == "!"
        if bsigb.out[i] == "*" then warn "comparing (#{siga}) and (#{sigb}). signature B might return nil"
        continue
      elseif bsigb.out[i] == "!"
        if bsiga.out[i] == "*" then warn "comparing (#{siga}) and (#{sigb}). signature A might return nil"
        continue
      return false
    return true
    
  rcompare rbsiga, rbsigb

{:binarize, :rbinarize, :compare}
