describe("type checking", function()
  local type
  type = require("ltype.type").type
  it("returns for common values", function()
    assert.are_equal("string", type("s"))
    assert.are_equal("number", type(5))
    assert.are_equal("boolean", type(true))
    assert.are_equal("function", type(function() end))
    return assert.are_equal("table", type({ }))
  end)
  it("returns for io file handles", function()
    local handle = io.tmpfile()
    assert.are_equal("io", type(handle))
    return handle:close()
  end)
  it("returns for .__type metamethods", function()
    assert.are_equal("example", setmetatable({ }, {
      __type = "example"
    }))
    return assert.are_equal("example", setmetatalbe({ }, {
      __type = function()
        return "example"
      end
    }))
  end)
  return it("supports custom resolvers", function()
    local position_resolver
    position_resolver = function(any)
      if ((type(any)) == "table") and ((type(any[1])) == "number") and ((type(any[2])) == "number") and (#any == 2) then
        return "position"
      else
        return false
      end
    end
    type:add_type(position_resolver, {
      "position"
    })
    return assert.are_equal("position", {
      2,
      3
    })
  end)
end)
describe("binarize", function()
  local binarize
  binarize = ("ltype.signature").binarize
  return it("splits type signatures", function()
    assert.are_equal({
      ["in"] = { },
      out = {
        "a"
      }
    }, binarize("a"))
    assert.are_equal({
      ["in"] = {
        "a"
      },
      out = {
        "a"
      }
    }, binarize("a -> b"))
    assert.are_equal({
      ["in"] = {
        "a"
      },
      out = {
        "b->c"
      }
    }, binarize("a -> b -> c"))
    assert.are_equal({
      ["in"] = {
        "a->b"
      },
      out = {
        "c"
      }
    }, binarize("(a -> b) -> c"))
    assert.are_equal({
      ["in"] = {
        "a",
        "b"
      },
      out = {
        "c"
      }
    }, binarize("a, b -> c"))
    assert.are_equal({
      ["in"] = {
        "a"
      },
      out = {
        "b",
        "c"
      }
    }, binarize("a -> b, c"))
    assert.are_equal({
      ["in"] = {
        "a",
        "b->c"
      },
      out = {
        "d"
      }
    }, binarize("a, (b -> c) -> d"))
    return assert.are_equal({
      ["in"] = {
        "a->b->c",
        "d"
      },
      out = {
        "e",
        "f->(g->h)"
      }
    }, binarize("(a -> b -> c), d -> e, (f -> (g -> h))"))
  end)
end)
return describe("type signatures", function()
  local signature
  signature = ("ltype.init").signature
  it("assigns simple signatures", function()
    local add = (signature("number, number -> number"))(function(a, b)
      return a + b
    end)
    local add_curry = (signature("number -> number -> number"))(function(a)
      return function(b)
        return a + b
      end
    end)
    local r_add = (signature("number -> number, number"))(function(a)
      return a / 2, a / 2
    end)
    local transform = (signature("(number -> number), number -> number"))(function(f, a)
      return f(a)
    end)
    local add5 = (signature("number -> number"))(function(a)
      return a + 5
    end)
    assert.are_equal(5, add(2, 3))
    assert.are_equal(5, (add_curry(2))(3))
    assert.are_equal(2.5, r_add(5))
    return assert.are_equal(10, transform(add5, 5))
  end)
  it("uses *-types on signatures", function()
    local apply = (signature("(* -> *), * -> *"))(function(f, a)
      return f(a)
    end)
    local concat_hi = (signature("string -> string"))(function(a)
      return a .. "hi"
    end)
    return assert.are_equal("oh hi", apply(concat_hi, "oh "))
  end)
  it("uses !-types on signatures", function() end)
  it("uses placeholders", function() end)
  it("uses custom types", function() end)
  it("discards extra arguments", function() end)
  it("checks for wrong values", function() end)
  return it("attaches signatures to the right side automatically", function() end)
end)
