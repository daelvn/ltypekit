-- ltype | 26.11.2018
-- By daelvn
-- Test suite

describe "type checking", ->
  import type from require "ltype.type"
  
  it "returns for common values", ->
    assert.are_equal "string",   type "s"
    assert.are_equal "number",   type 5
    assert.are_equal "boolean",  type true
    assert.are_equal "function", type ->
    assert.are_equal "table",    type {}
  it "returns for io file handles", ->
    handle = io.tmpfile!
    assert.are_equal "io", type handle
    handle\close!
  it "returns for .__type metamethods", ->
    assert.are_equal "example", setmetatable {}, {__type: "example"}
    assert.are_equal "example", setmetatalbe {}, {__type: -> "example"}
  it "supports custom resolvers", ->
    position_resolver = (any) ->
      if ((type any)    == "table") and
         ((type any[1]) == "number") and
         ((type any[2]) == "number") and
         (#any == 2)
        "position"
      else false
    type\add_type position_resolver, {"position"}
    assert.are_equal "position", {2, 3}

describe "binarize", ->
  import binarize from "ltype.signature"

  it "splits type signatures", ->
    assert.are_equal {in: {}, out: {"a"}},                          binarize "a"
    assert.are_equal {in: {"a"}, out: {"a"}},                       binarize "a -> b"
    assert.are_equal {in: {"a"}, out: {"b->c"}},                    binarize "a -> b -> c"
    assert.are_equal {in: {"a->b"}, out: {"c"}},                    binarize "(a -> b) -> c"
    assert.are_equal {in: {"a","b"}, out: {"c"}},                   binarize "a, b -> c"
    assert.are_equal {in: {"a"}, out: {"b","c"}},                   binarize "a -> b, c"
    assert.are_equal {in: {"a","b->c"}, out: {"d"}},                binarize "a, (b -> c) -> d"
    assert.are_equal {in: {"a->b->c","d"}, out: {"e","f->(g->h)"}}, binarize "(a -> b -> c), d -> e, (f -> (g -> h))"

describe "type signatures", ->
  import signature from "ltype.init"

  it "assigns simple signatures", ->
    add         = (signature "number, number -> number")             (a, b)     -> a + b
    add_curry   = (signature "number -> number -> number")           (a) -> (b) -> a + b
    r_add       = (signature "number -> number, number")             (a)        -> return a/2, a/2
    transform   = (signature "(number -> number), number -> number") (f, a)     -> f a
    add5        = (signature "number -> number")                     (a)        -> a+5

    assert.are_equal 5,   add 2, 3
    assert.are_equal 5,   (add_curry 2) 3
    assert.are_equal 2.5, r_add 5
    assert.are_equal 10,  transform add5, 5
  it "uses *-types on signatures", ->
    apply     = (signature "(* -> *), * -> *") (f, a) -> f a
    concat_hi = (signature "string -> string") (a)    -> a.."hi"
    assert.are_equal "oh hi", apply concat_hi, "oh "
  it "uses !-types on signatures", ->
    apply     = (signature "(! -> !), ! -> *") (f, a) -> f a
    concat_hi = (signature "string -> string") (a)    -> a.."hi"
    assert.are_equal "oh hi", apply concat_hi, "oh "
  it "uses placeholders", ->
    apply     = (signature "(x -> y), x -> y") (f, a) -> f a
    tonumber_ = (signature "(* -> number)")    (a)    -> tonumber a
    assert.are_equal 5, apply tonumber
    f = (signature ""
  it "uses custom types", ->
  it "discards extra arguments", ->
  it "checks for wrong values", ->
  it "attaches signatures to the right side automatically", ->
