-- ltypekit | 15.12.2018
-- By daelvn
-- Signature parsing and comparison
import die, warn from require "ltypekit.util"
import printi    from require "ltext"

is_union = (u) ->
  if (type u) != "table" then false
  if (u[1] == 0)               and
     ((type u[2]) == "string") and
     ((type u[3]) == "string")
    true
  else
    false

is_generic = (g) ->
  if (type g) != "table" then false
  if (g[1] == 1)               and
     ((type g[2]) == "string") and
     ((type g[3]) == "string")
    true
  else
    false

binarize = (sig) ->
  -- We have to support
  --  * Types                          string       {kind:"literal",value:"string"}
  --  * Type parameters                a            {kind:"literal",value:"a"}
  --  * Unspecified unions             *            {kind:"literal",value:"*",except_nil:false}
  --  * Unions                         [a|b]        {kind:"union",tree:{"a", "b"}}
  --  * Parameter generics             a<Integer>   {kind:"generic",parameter:"a",generic:"Integer"}
  --  * Unions in parameter generics   a<x|y>       {kind:"generic",parameter:"a",generic:{"x", "y"}}
  --  * Vararg                         ...          {kind:"literal",value:"..."}
  
  -- "Closed tables" (inside a side)
  -- {0,"string","number"}      -- union
  -- {1,"x","string", "number"} -- generic
  SIG = {signature: sig}

  tree  = in: {}, out: {}
  right = false

  depth =
    general: 0
    union:   0
    generic: 0

  _stack = {}
  stack  =
    push: (x) -> table.insert _stack, 1, x
    pop:      -> table.remove _stack, 1
    peek:     -> _stack[1]

  cache =
    in:       ""
    out:      ""
    iunion:   ""
    igeneric: ""

    union:   {0}
    generic: {1}

  cache.current = -> if right then cache.out else cache.in

  lookbehind = {}

  agglutinate =
    io:      (c) ->
      print "Agglutinating #{c}"
      if right then cache.out ..= c else cache.in ..= c
    union:   (c) -> cache.iunion   ..= c
    generic: (c) -> cache.igeneric ..= c

  attach =
    union:   ->
      table.insert cache.union, cache.iunion
      cache.iunion = ""
    generic: ->
      table.insert cache.generic, cache.igeneric
      cache.igeneric = ""

  push =
    io:      ->
      if right
        table.insert tree.out, cache.out
        cache.out = ""
      else
        table.insert tree.in, cache.in
        cache.in = ""
    union:   ->
      if right
        table.insert tree.out, cache.union
        cache.union = {0}
      else
        table.insert tree.in, cache.union
        cache.union = {0}
    generic: ->
      if right
        table.insert tree.out, cache.generic
        cache.generic = {1}
      else
        table.insert tree.in, cache.generic
        cache.generic = {1}
  
  attach.or = ->
    if stack.peek! == "["
      attach.union!
    elseif stack.peek! == "<"
      attach.generic!
    else
      die SIG, "binarize $ attempt to use '|' at unknown point."

  agglutinate.x = (c) ->
    if stack.peek! == "["
      agglutinate.union c
    elseif stack.peek! == "<"
      agglutinate.generic c
    else
      agglutinate.io c

  count = 1
  for char in sig\gmatch "."
    switch char
      when " "
        continue
      -- Parenthesis
      when "("
        depth.general += 1
        stack.push "("
        agglutinate.io char
      when ")"
        if stack.peek! != "("
          die SIG, "binarize $ unmatching parenthesis () (index: #{count})"
        stack.pop!
        depth.general -= 1
        agglutinate.io char
      -- Unions
      when "["
        depth.union += 1
        stack.push "["
      when "]"
        if stack.peek! != "["
          die SIG, "binarize $ unmatching square brackets [] (index: #{count})"
        stack.pop!
        depth.union -= 1
        attach.union!
        push.union!
      when "-"
        if     right              then agglutinate.io char
        elseif depth.generic > 0  then agglutinate.io char
      -- Generics
      when "<"
        depth.generic += 1
        stack.push "<"
        -- We have to push the parameter initializer here too
        agglutinate.generic cache.current!
        if right then cache.out = "" else cache.in = ""
        attach.generic!
      when ">"
        -- Symbol exception
        if (lookbehind[count-1] == "-")
          if     right then agglutinate.io char
          elseif depth.general == 0
            push.io!
            right = true
          else
            agglutinate.io char
        else
          if stack.peek! != "<"
            die SIG, "binarize $ unmatching angle brackets <> (index: #{count})"
          stack.pop!
          depth.generic -= 1
          attach.generic!
          push.generic!
      when "|"
        attach.or!
      when ","
        if depth.general == 0
          push.io!
        else agglutinate.io char
      when "-"
        symbol = true
      else
        agglutinate.x char
    count += 1
    table.insert lookbehind, char
  -- Last push
  push.io!
  -- Fix :: x -> () ==> :: x
  if #tree.out < 1
    tree.out = tree.in
    tree.in  = {}
  -- Fix :: (a -> b) ==> :: a -> b
  for n, argument in ipairs tree.in
    if (type argument) != "string" then continue
    if argument\match "%(.+%)"     then tree.in[n] = argument\sub 2, -2
  for n, argument in ipairs tree.out
    if (type argument) != "string" then continue
    if argument\match "%(.+%)"     then tree.out[n] = argument\sub 2, -2
  -- Fix empty strings
  remove_empty = (t) ->
    for k, v in pairs t do
      if (type v) == "table"
        t[k] = remove_empty v
      else
        if v == ""
          table.remove t, k
    t
  remove_empty tree.in
  remove_empty tree.out
  -- Automatically assign generics
  assign_generics = (t,known={}) ->
    for k, v in pairs t do
      if (type v) == "table"
        if v[1] == 1
          known[v[2]] = v
        else
          t[k] = assign_generics v, known
      elseif (type v) == "string"
        if known[v]
          t[k] = known[v]
      else continue
    t
  assign_generics tree
  -- Return binarized tree
  tree

rbinarize = (sig) ->
  tree = binarize sig
  for i=1, #tree.in
    if (type tree.in[i]) == "string"
      if tree.in[i]\match "%->" then tree.in[i] = rbinarize tree.in[i]
      if tree.in[i] == ""       then table.remove tree.in, i
  for i=1, #tree.out
    if (type tree.out[i]) == "string"
      if tree.out[i]\match "%->" then tree.out[i] = rbinarize tree.out[i]
      if tree.out[i] == ""       then table.remove tree.out, i
  tree

compare = (a, b, _safe, _silent) ->
  SIG = {signature: "#{a}; #{b}"}

  ra = rbinarize a
  rb = rbinarize b

  warn_ = warn
  warn = (s) ->
    if _safe       then die SIG, s
    if not _silent then warn_ s

  is_string = (s) -> (type s) == "string"
  is_table  = (t) -> (type t) == "table"
  is_number = (n) -> (type n) == "number"

  rcompare = (ta, tb) ->
    if #ta.in  != #tb.in  then false
    if #ta.out != #tb.out then false

    -- Cases to check:
    -- "x" == "x"
    -- *   == *
    -- !   == !
    -- *   == !    WARN

    -- {0,"x","y"}     == {0,"x","y"}
    -- {1,"a","x","y"} == {1,"a","x","y"}
    -- {0,"x","y"}     == {0,"x"}           WARN
    -- {1,"a","x","y"} == {1,"a","x"}       WARN

    for i=1, #ta.in
      if is_table ta.in[i]
        if is_table tb.in[i]
          -- Union, Generic, rcompare
          xa = ta.in[i]
          xb = tb.in[i]

          if xa[1] == 0
            -- Union
            common    = 0
            notcommon = 0
            didset    = false
            for atype in *xa[2,]
              for btype in *xb[2,]
                if atype == btype
                  common += 1
                  didset  = true
              if didset
                didset = false
              else
                notcommon += 1
            --
            if notcommon > 0
              warn "comparing union (##{xa}) and (##{xb}}, there are #{notcommon} unmatching types"
            if common == 0
              return false
            continue
          elseif xa[1] == 1
            -- Generic
            common    = 0
            notcommon = 0
            didset    = false
            for atype in *xa[3,]
              for btype in *xa[3,]
                print "Comparing types #{atype}, #{btype}"
                if atype == btype
                  common += 1
                  didset  = true
              if didset
                didset = false
              else
                notcommon += 1
            --
            if notcommon > 0
              warn "1:#{common} comparing generic (##{xa}) and (##{xb}), there are #{notcommon} unmatching types"
            if common == 0
              return false
            continue
          else
            -- rcompare
            rcompare xa, xb
        elseif is_string tb.in[i]
          -- Union, Generic
          xa = ta.in[i]
          xb = tb.in[i]
          
          if xa[1] == 0
            -- Union
            common    = 0
            notcommon = 0
            didset    = false
            for atype in *xa[2,]
              if atype == xb
                common += 1
                didset  = true
              if didset
                didset = false
              else
                notcommon += 1
            --
            if notcommon > 0
              warn "comparing union (##{xa}) and (##{xb}}, there are #{notcommon} unmatching types"
            if common == 0
              return false
            continue
          elseif xa[1] == 1
            -- Generic
            common    = 0
            notcommon = 0
            didset    = false
            for atype in *xa[3,]
              if atype == xb
                common += 1
                didset  = true
              if didset
                didset = false
              else
                notcommon += 1
            --
            if notcommon > 0
              warn "2:#{common} comparing generic (##{xa}) and (##{xb}}, there are #{notcommon} unmatching types"
            if common == 0
              return false
            continue
          else
            -- Cannot compare table to string
            return false
        elseif is_number tb.in[i]
          die SIG, "compare $ Impossible error I"
        else
          die SIG, "compare $ Impossible error II"
      elseif is_string ta.in[i]
        if is_table tb.in[i]
          -- Union, Generic
          xa = ta.in[i]
          xb = tb.in[i]

          if xb[1] == 0
            -- Union
            common    = 0
            notcommon = 0
            didset    = false
            for atype in *xb[2,]
              if atype == xa
                common += 1
                didset  = true
              if didset
                didset = false
              else
                notcommon += 1
            --
            if notcommon > 0
              warn "comparing union (##{xa}) and (##{xb}}, there are #{notcommon} unmatching types"
            if common == 0
              return false
            continue
          elseif xb[1] == 1
            -- Generic
            common    = 0
            notcommon = 0
            didset    = false
            for atype in *xb[3,]
              if atype == xa
                common += 1
                didset  = true
              if didset
                didset = false
              else
                notcommon += 1
            --
            if notcommon > 0
              warn "3:#{common} comparing generic (##{xa}) and (##{xb}}, there are #{notcommon} unmatching types"
            if common == 0
              return false
            continue
          else
            -- Cannot compare table to string
            return false
        elseif is_string tb.in[i]
          -- Literal, Any, XAny
          xa = ta.in[i]
          xb = tb.in[i]

          if xa == xb                        then continue
          elseif (xa == "*") and (xb == "!") then warn "comparing A:(#{a}) and B:(#{b}). A might take nil."
          elseif (xa == "!") and (xb == "!") then warn "comparing A:(#{a}) and B:(#{b}). B might take nil."
          else
            return false
        else
          die SIG, "compare $ Impossible error III"
      else
        die SIG, "compare $ Impossible error IV"

    for i=1, #ta.out
      if is_table ta.out[i]
        if is_table tb.out[i]
          -- Union, Generic, rcompare
          xa = ta.out[i]
          xb = tb.out[i]

          if xa[1] == 0
            -- Union
            common    = 0
            notcommon = 0
            didset    = false
            for atype in *xa[2,]
              for btype in *xb[2,]
                if atype == btype
                  common += 1
                  didset  = false
              if didset
                didset = false
              else
                notcommon += 1
            --
            if notcommon > 0
              warn "comparing union (##{xa}) and (##{xb}}, there are #{notcommon} unmatching types"
            if common == 0
              return false
            continue
          elseif xa[1] == 1
            -- Generic
            common    = 0
            notcommon = 0
            didset    = false
            for atype in *xa[3,]
              for btype in *xa[3,]
                print atype, btype
                if atype == btype
                  common += 1
                  didset  = true
              if didset
                didset = false
              else
                notcommon += 1
            --
            if notcommon > 0
              warn "4:#{common} comparing generic (##{xa}) and (##{xb}), there are #{notcommon} unmatching types"
            if common == 0
              return false
            continue
          else
            -- rcompare
            rcompare xa, xb
        elseif is_string tb.out[i]
          -- Union, Generic
          xa = ta.out[i]
          xb = tb.out[i]
          
          if xa[1] == 0
            -- Union
            common    = 0
            notcommon = 0
            didset    = false
            for atype in *xa[2,]
              if atype == xb
                common += 1
                didset  = true
              if didset
                didset = false
              else
                notcommon += 1
            --
            if notcommon > 0
              warn "comparing union (##{xa}) and (##{xb}}, there are #{notcommon} unmatching types"
            if common == 0
              return false
            continue
          elseif xa[1] == 1
            -- Generic
            common    = 0
            notcommon = 0
            didset    = false
            for atype in *xa[3,]
              if atype == xb
                common += 1
                didset  = true
              if didset
                didset = false
              else
                notcommon += 1
            --
            if notcommon > 0
              warn "5:#{common} comparing generic (##{xa}) and (##{xb}}, there are #{notcommon} unmatching types"
            if common == 0
              return false
            continue
          else
            -- Cannot compare table to string
            return false
        elseif is_number tb.out[i]
          die SIG, "compare $ Impossible error I"
        else
          die SIG, "compare $ Impossible error II"
      elseif is_string ta.out[i]
        if is_table tb.out[i]
          -- Union, Generic
          xa = ta.out[i]
          xb = tb.out[i]

          if xb[1] == 0
            -- Union
            common    = 0
            notcommon = 0
            didset    = false
            for atype in *xb[2,]
              if atype == xa
                common += 1
                didset  = true
              if didset
                didset = false
              else
                notcommon += 1
            --
            if notcommon > 0
              warn "comparing union (##{xa}) and (##{xb}}, there are #{notcommon} unmatching types"
            if common == 0
              return false
            continue
          elseif xb[1] == 1
            -- Generic
            common    = 0
            notcommon = 0
            didset    = false
            for atype in *xb[3,]
              if atype == xa
                common += 1
                didset  = true
              if didset
                didset = false
              else
                notcommon += 1
            --
            if notcommon > 0
              warn "6:#{common} comparing generic (##{xa}) and (##{xb}}, there are #{notcommon} unmatching types"
            if common == 0
              return false
            continue
          else
            -- Cannot compare table to string
            return false
        elseif is_string tb.out[i]
          -- Literal, Any, XAny
          xa = ta.out[i]
          xb = tb.out[i]

          if xa == xb                        then continue
          elseif (xa == "*") and (xb == "!") then warn "comparing A:(#{a}) and B:(#{b}). A might take nil."
          elseif (xa == "!") and (xb == "!") then warn "comparing A:(#{a}) and B:(#{b}). B might take nil."
          else
            return false
        else
          die SIG, "compare $ Impossible error III"
      else
        die SIG, "compare $ Impossible error IV"
    return true

  rcompare ra, rb

{:is_union, :is_generic, :binarize, :rbinarize, :compare}
