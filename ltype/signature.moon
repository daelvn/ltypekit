-- ltypesign | 23.11.2018
-- By daelvn
-- Signature parsing
import die from require "ltype.util"

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

{:binarize}
