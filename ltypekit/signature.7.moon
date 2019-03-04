-- ltypekit | 07.01.2019
-- By daelvn
-- Signature parsing and comparison
import die, warn from require "ltypekit.util"
import printi    from require "ltext"
inspect = require "inspect"

_DEBUG = false

printfi = printi
printi  = (...) -> if _DEBUG then printfi ...

local *

-- has_top_level_constraint
has_top_level_constraint = (sig) ->
  depth   = 0
  pointer = 0
  expect  = false
  for char in sig\gmatch "."
    pointer += 1
    switch char
      when "("
        depth += 1
      when ")"
        depth -=1
        if depth < 0 then die SIG, "has_top_level_constraint $ unexpected ')' at #{pointer}"
      when "="
        if depth == 0 then expect = true
      when ">"
        if expect then return true
  if depth != 0 then die SIG, "has_top_level_constraint $ unmatching parenthesis in signature"
  return false

parse_constraint = (constraint) ->
  scope = {}
  --
  lookbehind = {}
  cache      =
    current:    ""
    types:      {0}
  --
  comma = "split"
  -- split:  split types
  -- list:   types in a list
  -- hash:   pairs in a hash
  -- choice: types in a choice
  pointer = 0
  for char in constraint\gmatch "."
    pointer += 1
    --print "#{pointer} -> #{char}"
    --printi {:comma, :cache, :scope}
    switch char
      when "(", ")"
        continue
      when "|"
        -- Start or end choice
        if comma == "choice"
          comma = "split"
        else
          comma = "choice"
          cache.types = {1}
        print comma
      when "[", "]"
        -- Start list
        if comma == "list"
          comma = "split"
        else
          comma = "list"
          cache.types = {2}
        print comma
      when "{", "}"
        -- Start hashmap
        if comma == "hash"
          comma = "split"
        else
          comma = "hash"
          cache.types = {3}
        print comma
      when " "
        unless lookbehind[#lookbehind] == ","
          table.insert cache.types, cache.current
          cache.current = ""
      when ","
        switch comma
          when "choice", "list", "hash"
            table.insert cache.types, cache.current
            cache.current = ""
          when "split"
            if scope[cache.current]
              table.insert scope[cache.current], cache.types
              cache.types   = {0}
              print "inserting into constraint for #{cache.current}"
              cache.current = ""
            else
              scope[cache.current] = {cache.types}
              cache.types   = {0}
              print "creating constraint for #{cache.current}"
              cache.current = ""
      else
        cache.current ..= char
    table.insert lookbehind, char
  if scope[cache.current]
    table.insert scope[cache.current], cache.types
    cache.types = {0}
    print "inserting into constraint for #{cache.current}"
    cache.current = ""
  else
    scope[cache.current] = {cache.types}
    cache.types = {0}
    print "creating constraint for #{cache.current}"
    cache.current = ""
  printi scope
  -- Constraint simplification
  if (#scope == 2) and scope[1] == 1
    scope = scope[2]
  -- Return
  scope

parse_declaration = (sig) ->
  SIG  = {signature: sig}
  tree = in: {}, out: {}
  --
  depth   = 0
  collecl = 0
  right   = false
  --
  comma = "split"
  -- split:      split arguments
  -- collection: split types in a list or hash
  --
  collection = "none"
  -- none: not in collection
  -- list: list
  -- hash: hashmap
  --
  inscope = false
  --
  lookbehind = {}
  cache      =
    collections: {}
    in:          ""
    out:         ""
    scope:       ""
  
  cache.current    =     -> if right then cache.out      else cache.in
  cache.setcurrent = (v) -> if right then cache.out = v  else cache.in = v
  cache.delcurrent =     -> if right then cache.out = "" else cache.in = ""
  --
  remove_empty = (t) ->
    for k, v in pairs t do
      if (type v) == "table"
        t[k] = remove_empty v
      else
        if ((type v) != "number") and (v\match "^[ \r\n\t]+$") or v == ""
          print "deleting #{k}"
          table.remove t, k
    t
  --
  agglutinate = (c) -> if right then cache.out ..= c else cache.in ..= c
  push        =     ->
    if right
      table.insert tree.out, cache.out
      cache.out = ""
    else
      table.insert tree.in, cache.in
      cache.in = ""

  --> Constraints
  -- type var =>                : Must be type
  -- typex var, typey var =>    : Must be both types
  -- |typex,typey| var =>       : Must be either type
  -- type a, type b =>          : Normal constraint
  -- (typex, typey a), type b   : Parentheses are ignored
  -- type * =>                  : All variables must be type

  --> Declaration
  -- -> a                       : Returns a
  -- a                          : Returns a
  -- a -> b                     : Takes a, returns b
  -- a, b -> c                  : Takes a and b, returns {
  -- a -> (b -> c)              : Takes a, returns function b -> c
  -- a -> b -> c                : Takes a, returns function b -> c
  -- a -> $(...)                : Initiates a new signature

  --> Representation
  -- "type"                     : Type
  -- "a"                        : Unconstrained variable
  -- {0, "a", "type"}           : Constrained variable
  -- {0, "a", "typex", "typey"} : Multiply constrained variable
  -- {1, "a", "typex", "typey"} : Choice constraint
  -- {2, "type"}                : List
  -- {3, "typex", "typey"}      : Hashmap

  pointer = 0
  for char in sig\gmatch "."
    pointer += 1
    printi cache
    printi tree
    if inscope
      switch char
        when ")"
          cache.setcurrent rbinarize cache.scope
          push!
          cache.scope = ""
          inscope = false
        else
          cache.scope ..= char
      continue
    -- not in a scope
    switch char
      when "$"
        if right or depth > 0 then agglutinate char
      when " "
        continue
      when "("
        depth += 1
        --if lookbehind[#lookbehind] == "$"
        --  inscope = true
        --else
        --  agglutinate char
        inscope = true
      when ")"
        depth -= 1
        if depth < 0 then die SIG, "parse_declaration $ unexpected ')' at #{pointer}"
        agglutinate char
      when "["
        if right
          agglutinate char
        elseif (depth == 0)
          collecl                   += 1
          collection                 = "list"
          cache.collections[collecl]  = {2}
        else
          agglutinate char
      when "]"
        if right
          agglutinate char
        elseif depth == 0
          -- close table logic
          table.insert cache.collections[collecl], cache.current!
          cache.delcurrent!
          remove_empty cache.collections[collecl]
          if collecl == 1
            if right
              table.insert tree.out, cache.collections[collecl]
            else
              table.insert tree.in, cache.collections[collecl]
          else
            table.insert cache.collections[collecl-1], cache.collections[collecl]
            cache.collections[collecl] = nil
          collecl -= 1
        else
          agglutinate char
      when "{"
        if right
          agglutinate char
        elseif depth == 0
          collecl                    += 1
          collection                  = "hash"
          cache.collections[collecl]  = {3}
        else
          agglutinate char
      when "}"
        if right
          agglutinate char
        elseif depth == 0
          -- close table
          table.insert cache.collections[collecl], cache.current!
          cache.delcurrent!
          if collecl == 1
            if right
              table.insert tree.out, cache.collections[collecl]
            else
              table.insert tree.in, cache.collections[collecl]
          else
            table.insert cache.collections[collecl-1], cache.collections[collecl]
            cache.collections[collecl] = nil
          collecl -= 1
        else
          agglutinate char
      when "-"
        if right or depth > 0 then agglutinate char
      when ">"
        if lookbehind[#lookbehind] == "-"
          if right
            agglutinate char
          elseif depth == 0
            push!
            right = true
          else
            agglutinate char
        else
          die SIG, "parse_declaration $ unexpected '>' at #{pointer}"
      when ","
        if depth == 0
          push!
        elseif collecl > 0
          table.insert cache.collections[collecl], cache.current!
          cache.delcurrent!
        else
          agglutinate char
      else
        agglutinate char
    table.insert lookbehind, char
  -- Last push
  push!
  -- Fix :: x -> () ==> :: x
  if #tree.out < 1
    tree.out = tree.in
    tree.in  = {}
  -- Fix :: (a -> b) ==> :: a -> b
  -- FIXME This will remove characters wrongly on signatures such as `c -> (a -> b)`
  for n, argument in ipairs tree.in
    if (type argument) != "string" then continue
    if argument\match "%(.+%)"     then tree.in[n] = argument\sub 2, -2
  for n, argument in ipairs tree.out
    if (type argument) != "string" then continue
    if argument\match "%(.+%)"     then tree.out[n] = argument\sub 2, -2
  -- Fix empty strings
  remove_empty tree.in
  remove_empty tree.out
  -- Return declaration
  tree

unify_constraints = (constraints) ->
  -- x -> single
  -- 1 -> choice
  -- 2 -> list
  -- 3 -> hash
  uconstraint = {}
  cache       =
    and:  {0}
    or:   {1}
    list: {2}
    hash: {3}
  -- First, insert each constraint into the appropiate category
  for ct in *constraints
    switch ct[1]
      when 0 -- single -> AND
        table.insert cache.and, ct[2]
      when 1 -- choice -> OR
        for i=2, #ct do table.insert cache.or, ct[i]
      when 2 -- list -> list
        for i=2, #ct do table.insert cache.list, ct[i]
      when 3 -- hash -> hash
        for i=2, #ct do table.insert cache.hash, ct[i]
  -- Now, use the due logic to merge all categories
  -- This is actually very simple, just wrap all categories in an OR
  -- and + or  = or{and,or}
  -- and + col = or{col,...}
  -- or  + col = or{col,...}
  -- col + col = or{col,col}
  uconstraint = {1, cache.and, cache.or, cache.list, cache.hash}
  for i=2,#uconstraint do
    if #uconstraint[i] == 1 then uconstraint[i] = nil
  -- Constraint simplification
  if (#uconstraint == 2) and uconstraint[1] == 1
    uconstraint = uconstraint[2]
  -- Return
  uconstraint

apply_constraint = (tree, variable, constraintl) ->
  unless constraintl[variable] then return false
  _helper = (t) ->
    for k, v in pairs t do
      if (type v) == "table"
        if (type v[1]) == "number"
          if v[1]           == 4        then continue
          if (type t[k][2]) != "string" then continue
          --
          t[k][2] = {4, variable, unify_constraints constraintl[variable]}
          print "applying constraint to #{variable} (hash/list)"
          printi constraintl[variable]
          printi t[k]
        else
          t[k] = _helper v
      else
        if v == variable
          t[k] = {4, variable, unify_constraints constraintl[variable]}
          print "applying constraint to #{variable}"
          printi constraintl[variable]
          printi t[k]
    t
  _helper tree


get_constraints = (sig) -> sig\match "(.-) *=> *.+"
get_declaration = (sig) -> sig\match ".- *=> *(.+)"

get_key = (pair) -> pair\match "(.-):.+"
get_val = (pair) -> pair\match ".-:(.+)"

-- binarize will now parse the constraints and parse the declarations, then merge
-- both trees.
binarize = (sig, const) ->
  tree = {in: {}, out: {}}
  if has_top_level_constraint sig
    print "using passed-in constraints" if const
    side_constraint   = get_constraints sig
    side_declaration  = get_declaration sig
    constraints       = const or parse_constraint side_constraint
    declaration       = parse_declaration side_declaration
    for variable, _ in pairs constraints do declaration = apply_constraint declaration, variable, constraints
    tree.in  = declaration.in
    tree.out = declaration.out
    tree, constraints
  else
    declaration      = parse_declaration sig
    if const
      print "explicitly passed-in constraints"
      constraints = const
      for variable, _ in pairs constraints do declaration = apply_constraint declaration, variable, constraints
    tree.in          = declaration.in
    tree.out         = declaration.out
    tree


-- rbinarize: recursive binarizing
rbinarize = (sig, const) ->
  tree, constraints = binarize sig, const
  for i=1, #tree.in
    if (type tree.in[i]) == "string"
      if tree.in[i]\match "%->" then tree.in[i] = rbinarize tree.in[i], constraints
      if tree.in[i] ==    ""    then table.remove tree.out, i
  for i=1, #tree.out
    if (type tree.out[i]) == "string"
      if tree.out[i]\match "%->" then tree.out[i] = rbinarize tree.out[i], constraints
      if tree.out[i] ==    ""    then table.remove tree.out, i
  tree

printfi parse_declaration "a"
printfi parse_constraint  "Num a, |Int,Double| a"
printfi unify_constraints (parse_constraint "Num a, Int a, |Int,Double| a").a
printfi binarize "Num a => a"
printfi binarize  "Num a, Int b => [a] -> b -> b"
printfi rbinarize "a, b => [a] -> b -> b"
printfi rbinarize "* a, * b => (a => [a] -> a) -> b"
printfi rbinarize "* a, * b => ([a] -> a) -> b"

-- compare: compares two signatures
