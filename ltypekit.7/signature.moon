--> # ltypekit
--> Advanced type checking library for Lua.
-- ltypekit.7/type
-- By daelvn
-- 01.03.2018
inspect = require "inspect"
ts      = require "tableshape"
--
insert = (t) -> (v) -> table.insert t, v

--> # Tableshape shortcuts
T = ts.types
S = T.shape

--> # Tableshape tests
--> String tests in tableshape
beginsUpper = T.pattern "^%u"
beginsLower = T.pattern "^%l"

--> # Tokenizing
--> Create tokens out of the signature stream
--> ## prepare
--> Prepares the input to be processed
prepare = (sig) ->
  sig = sig\gsub " %-> ", "->"
  sig = sig\gsub " %=> ", "=>"
  sig

--> ## inspectStream
--> Prints the tokenStream into stdout.
inspectStream = (tokenStream) ->
  for token in *tokenStream
    print token[1], token[2]\gsub " ", "_"
--> ## Token constructors
--> Functions to have an easier to read token constructing syntax.
Ref         = (tag) -> { "ref", tag } if tag\match "%S"
Arrow       = { "arr", "->" }
Constraint  = { "con", "=>" }
Parenthesis = (tag) -> { "par", tag }
List        = (tag) -> { "lst", tag }
Separator   = (tag) -> { "sep", tag }
--> ## tokenize
--> Tokenizer function
tokenize = (sig) ->
  --
  tokenStream = {pointer: 1}
  intoStream  = insert tokenStream
  --
  point = 0
  await = false
  cache = ""
  --
  for char in (prepare sig)\gmatch "."
    point += 1
    switch char
      when "(", ")"
        intoStream Ref cache
        intoStream Parenthesis char
        cache = ""
      when "[", "]"
        intoStream Ref cache
        intoStream List char
        cache = ""
      when ",", " "
        intoStream Ref cache
        intoStream Separator char
        cache = ""
      when "-"
        intoStream Ref cache
        await = "arrow"
        cache = ""
      when "="
        intoStream Ref cache
        await = "constraint"
        cache = ""
      when ">"
        switch await
          when "arrow"      then intoStream Arrow
          when "constraint" then intoStream Constraint
          else
            error "tokenize :: Unexpected '>' at char #{point}"
        await = false
      else
        cache ..= char
  --
  intoStream Ref cache
  cache = ""
  --
  tokenStream

--> # Token accessing
--> Functions to access, consume and expect tokens.
--> ## nextToken
--> Returns the next, non-consumed token
nextToken = (tokenStream) -> -> tokenStream[tokenStream.pointer]
--> ## consume
--> Consumes a token
consumeToken = (tokenStream) -> (ask) ->
  token = (nextToken tokenStream)!
  if token[1] == ask[1] and token[2] == (ask[2] or token[2])
    tokenStream.pointer += 1
    token
  false
--> ## expect
--> Consumes a token, but errors if it's not the expected token
expectToken = (tokenStream) -> (expected) ->
  token = (nextToken tokenStream)!
  if token[1] == expected[1] and token[2] == (expected[2] or token[2])
    tokenStream.pointer += 1
    token
  else
    error "expect :: Expected '#{expected}', got '#{token[1]}' (value '#{token[2]}' at token #{tokenStream.pointer})"

--> # AST creation
--> Functions to form an AST
--> ## Node creation
--> Create table nodes to build an AST
NTypeAtom = (ref) -> {"ref", ref}
NTypeList = (app) -> {"lst", app}
-- TODO NTypeTuple, NTypeApplication, NType
--> ## Shape creation
--> Create tableshapes to match the AST
STypeAtom = (ref) -> S { "ref", (beginUpper ref) and ref or beginLower }
-- TODO Does this really work?
STypeList = (app) -> S { "lst", app }
-- TODO STypeTuple, STypeApplication, SType
--> # Parsing
--> Creating an AST out of the token stream. 
--> ## parse
--> Parsing function
parse = (tokenStream) ->
  expect  = expectToken  tokenStream
  consume = consumeToken tokenStream
  next    = nextToken    tokenStream
  --> ### Grammar units
  --> ```bnf
  --> TypeAtom        ::= ref
  -->                   | "(" Type ")"
  --> TypeList        ::= "[" TypeApplication "]"
  --> TypeTuple       ::= "(" TypeApplication ["," TypeApplication ]* ")"
  --> TypeApplication ::= TypeAtom (TypeAtom)*
  --> Type            ::= TypeApplication
  -->                   | TypeApplication "=>" TypeApplication
  -->                   | TypeApplication "->" TypeApplication
  --> ```
  local TypeAtom, TypeList, TypeTuple, TypeApplication, Type
  --> #### TypeAtom
  TypeAtom = ->
    if consume Parenthesis "("
      t = Type!
      expect Parenthesis ")"
      t
    else
      return
        (NTypeAtom expect {"ref"}),
        (STypeAtom expect {"ref"})
  --> #### TypeList
  TypeList = ->
    expect List "["
    ta = TypeApplication!
    expect List "]"
    return
      (NTypeList ta)
      (STypeList ta)
  --> #### TypeTuple
  TypeTuple = ->
    expect Parenthesis "("
    ta = TypeApplication!
    -- TODO This is totally wrong and just done so it compiles
    return if consume Separator ","
  --> #### TypeApplication
  TypeApplication = ->
    head  = TypeAtom!
    token = next!
    while (token[1] == "ref") or ((token[1] == "par") and (token[2] == ")"))
      -- TODO Where does STypeApplication come in?
      head = NTypeApplication {head, TypeAtom!}
    return head
  -- TODO Type


  --

--inspectStream tokenize "a -> (b -> c)"
--print!
inspectStream tokenize "Ord a => a -> (a -> Bool) -> Bool"
--print!
--inspectStream tokenize "Ord a -> Ord a -> Bool"
