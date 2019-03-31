local inspect = require("inspect")
local ts = require("tableshape")
local inspectAST = inspect
local insert
insert = function(t)
  return function(v)
    return table.insert(t, v)
  end
end
local pack
pack = function(...)
  return {
    ...
  }
end
local map
map = function(f)
  return function(t)
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #t do
      local v = t[_index_0]
      _accum_0[_len_0] = f(v)
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end
end
local unpack = unpack or table.unpack
local T = ts.types
local S = T.shape
local beginsUpper = T.pattern("^%u")
local beginsLower = T.pattern("^%l")
local prepare
prepare = function(sig)
  sig = sig:gsub(" %-> ", "->")
  sig = sig:gsub(" %=> ", "=>")
  return sig
end
local inspectStream
inspectStream = function(tokenStream)
  for _index_0 = 1, #tokenStream do
    local token = tokenStream[_index_0]
    print(token[1], token[2]:gsub(" ", "_"))
  end
end
local Ref
Ref = function(tag)
  if tag:match("%S") then
    return {
      "ref",
      tag
    }
  end
end
local Arrow = {
  "arr",
  "->"
}
local Constraint = {
  "con",
  "=>"
}
local Parenthesis
Parenthesis = function(tag)
  return {
    "par",
    tag
  }
end
local List
List = function(tag)
  return {
    "lst",
    tag
  }
end
local Separator
Separator = function(tag)
  return {
    "sep",
    tag
  }
end
local tokenize
tokenize = function(sig)
  local tokenStream = {
    pointer = 1
  }
  local intoStream = insert(tokenStream)
  local point = 0
  local await = false
  local cache = ""
  for char in (prepare(sig)):gmatch(".") do
    point = point + 1
    local _exp_0 = char
    if "(" == _exp_0 or ")" == _exp_0 then
      intoStream(Ref(cache))
      intoStream(Parenthesis(char))
      cache = ""
    elseif "[" == _exp_0 or "]" == _exp_0 then
      intoStream(Ref(cache))
      intoStream(List(char))
      cache = ""
    elseif "," == _exp_0 or " " == _exp_0 then
      intoStream(Ref(cache))
      intoStream(Separator(char))
      cache = ""
    elseif "-" == _exp_0 then
      intoStream(Ref(cache))
      await = "arrow"
      cache = ""
    elseif "=" == _exp_0 then
      intoStream(Ref(cache))
      await = "constraint"
      cache = ""
    elseif ">" == _exp_0 then
      local _exp_1 = await
      if "arrow" == _exp_1 then
        intoStream(Arrow)
      elseif "constraint" == _exp_1 then
        intoStream(Constraint)
      else
        error("tokenize :: Unexpected '>' at char " .. tostring(point))
      end
      await = false
    else
      cache = cache .. char
    end
  end
  intoStream(Ref(cache))
  cache = ""
  return tokenStream
end
local nextToken
nextToken = function(tokenStream)
  return function()
    return tokenStream[tokenStream.pointer]
  end
end
local consumeToken
consumeToken = function(tokenStream)
  return function(ask)
    local token = (nextToken(tokenStream))()
    if token[1] == ask[1] and token[2] == (ask[2] or token[2]) then
      tokenStream.pointer = tokenStream.pointer + 1
      local _ = token
    end
    return false
  end
end
local expectToken
expectToken = function(tokenStream)
  return function(expected)
    local token = (nextToken(tokenStream))()
    if token[1] == expected[1] and token[2] == (expected[2] or token[2]) then
      tokenStream.pointer = tokenStream.pointer + 1
      return token
    else
      return error("expect :: Expected '" .. tostring(expected) .. "', got '" .. tostring(token[1]) .. "' (value '" .. tostring(token[2]) .. "' at token " .. tostring(tokenStream.pointer) .. ")")
    end
  end
end
local NTypeAtom
NTypeAtom = function(...)
  return pack("atom", ...)
end
local NTypeApplication
NTypeApplication = function(head)
  return function(atom)
    return {
      "app",
      head,
      atom
    }
  end
end
local NType
NType = function(left)
  return function(arrow)
    return function(right)
      return {
        __context = "inherit",
        __arrow = arrow,
        "type",
        left,
        right
      }
    end
  end
end
local STypeAtom
STypeAtom = function(ref)
  return S(pack("atom", unpack((map(function(ref)
    return ((type(ref)) == "string") and ((beginUpper(ref)) and ref or beginLower) or ref
  end))({
    ...
  }))))
end
local STypeApplication
STypeApplication = function(head)
  return function(atom)
    return S({
      "app",
      head,
      atom
    })
  end
end
local SType
SType = function(left)
  return function(arrow)
    return function(right)
      return S({
        __context = T.one_of({
          "inherit",
          T.array_of(T.string)
        }, {
          __arrow = arrow
        }, "type", left, right)
      })
    end
  end
end
local parse
parse = function(tokenStream)
  local expect = expectToken(tokenStream)
  local consume = consumeToken(tokenStream)
  local next = nextToken(tokenStream)
  local TypeAtom, TypeApplication, Type
  TypeAtom = function()
    if consume(Parenthesis("(")) then
      local n, s
      do
        local _obj_0 = Type()
        n, s = _obj_0.n, _obj_0.s
      end
      if n[1] == "type" then
        expect(Parenthesis(")"))
        return n, s
      elseif n[1] == "app" then
        expect(Separator(","))
        local node = {
          {
            TypeApplication()
          }
        }
        local append = (insert(node))
        while true do
          if consume(Separator(",")) then
            append({
              TypeApplication()
            })
          else
            break
          end
        end
        return {
          n = NTypeAtom(unpack(node)),
          s = STypeAtom(unpack)
        }
      end
    elseif consume(List("[")) then
      local n, s
      do
        local _obj_0 = TypeApplication()
        n, s = _obj_0.n, _obj_0.s
      end
      expect(List("]"))
      return {
        n = n,
        s = s
      }
    else
      return {
        n = NTypeAtom(expect({
          "ref"
        })),
        s = STypeAtom(expect({
          "ref"
        }))
      }
    end
  end
  TypeApplication = function()
    local head = TypeAtom()
    local token = next()
    while token[1] == "ref" or token[2] == "(" do
      head.n = (NTypeApplication(head.n))(token.n)
      head.s = (STypeApplication(head.s))(token.s)
    end
    return head.n, head.s
  end
  Type = function()
    local left = TypeApplication()
    local token = next()
    if token[2] == "->" then
      local right = TypeApplication()
      return {
        n = ((NType(left))("->"))(right),
        s = ((SType(left))("->"))(right)
      }
    elseif token[2] == "=>" then
      local right = TypeApplication()
      return {
        n = ((NType(left))("=>"))(right),
        s = ((SType(left))("=>"))(right)
      }
    else
      return left
    end
  end
  return Type()
end
inspectStream(tokenize("Ord a => a -> (a -> Bool) -> Bool"))
return inspectAST(tokenize("a -> b"))
