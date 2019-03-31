--> # ltypekit
--> Advanced type checking library for Lua.
-- ltypekit.7/type
-- By daelvn
-- 01.03.2018
inspect = require "inspect"
ts      = require "tableshape"
--
inspectAST = (...) -> print inspect ...
--
insert   = (t) -> (v) -> table.insert t, v
pack     = (...)      -> {...}
map      = (f) -> (t) -> [f v for v in *t]
unpack or= table.unpack

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
NTypeAtom        = (...)  -> pack "atom", ...
NTypeApplication = (head) -> (atom) -> { "app", head, atom }
NType            = (left) -> (arrow) -> (right) -> {__context: "inherit", __arrow: arrow, "type", left, right }

--> ## Shape creation
--> Create tableshapes to match the AST
STypeAtom        = (...)  -> S pack "atom", unpack (map (ref) -> ((type ref) == "string") and ((beginUpper ref) and ref or beginLower) or ref) {...}
STypeApplication = (head) -> (atom) -> S { "app", head, atom }
SType            = (left) -> (arrow) -> (right) -> S { __context: T.one_of {"inherit", T.array_of T.string}, __arrow: arrow, "type", left, right }

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
  -->                   | "[" TypeApplication "]"
  -->                   | "(" TypeApplication "," TypeApplication {"," TypeApplication} ")"
  --> TypeApplication ::= TypeAtom {TypeAtom}
  --> Type            ::= TypeApplication
  -->                   | TypeApplication "=>" TypeApplication
  -->                   | TypeApplication "->" TypeApplication
  --> ```
  local TypeAtom, TypeApplication, Type
  --> #### TypeAtom
  TypeAtom = ->
    if consume Parenthesis "("
      {:n, :s} = Type!
      if n[1] == "type"
        expect Parenthesis ")"
        return n, s
      elseif n[1] == "app"
        expect Separator ","
        node   = {{TypeApplication!}}
        append = (insert node)
        while true
          if consume Separator ","
            append {TypeApplication!}
          else break
        return {
          n: NTypeAtom unpack node
          s: STypeAtom unpack
        }
    elseif consume List "["
      {:n, :s} = TypeApplication!
      expect List "]"
      return {:n, :s}
    else
      return {
        n: NTypeAtom expect {"ref"}
        s: STypeAtom expect {"ref"}
      }
  --> #### TypeApplication
  TypeApplication = ->
    head  = TypeAtom!
    token = next!
    while token[1] == "ref" or token[2] == "("
      head.n = (NTypeApplication head.n) token.n
      head.s = (STypeApplication head.s) token.s
    return head.n, head.s
  --> #### Type
  Type = ->
    left  = TypeApplication!
    token = next!
    if token[2] == "->"
      right = TypeApplication!
      return {
        n: ((NType left) "->") right
        s: ((SType left) "->") right
      }
    elseif token[2] == "=>"
      right = TypeApplication!
      return {
        n: ((NType left) "=>") right
        s: ((SType left) "=>") right
      }
    else
      left

  Type!

--inspectStream tokenize "a -> (b -> c)"
--print!
inspectStream tokenize "Ord a => a -> (a -> Bool) -> Bool"
--print!
--inspectStream tokenize "Ord a -> Ord a -> Bool"
{:n, :s} = parse "a -> b"
inspectAST n
inspectAST s
