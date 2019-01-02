local sign
sign = require("ltypekit").sign
local typeof
typeof = require("ltypekit.type").typeof
local char_resolver
char_resolver = function(any)
  if ((type(any)) == "string") and any:len() == 1 then
    return "char"
  else
    return false
  end
end
typeof:add("char", char_resolver)
local Char = sign("[string|char] -> char")
Char(function(c)
  return c:sub(1, 1)
end)
local ab = "* -> boolean"
local cb = "char -> boolean"
local cc = "char -> char"
local test = (sign(ab))(function(any)
  if any then
    return true
  else
    return false
  end
end)
local isChar = (sign(ab))(function(any)
  return (char_resolver(any)) == "char"
end)
local isControl = (sign(cb))(function(c)
  return test(c:match("%c"))
end)
local isSpace = (sign(cb))(function(c)
  return test(c:match("%s"))
end)
local isLower = (sign(cb))(function(c)
  return test(c:match("%l"))
end)
local isUpper = (sign(cb))(function(c)
  return test(c:match("%u"))
end)
local isAlpha = (sign(cb))(function(c)
  return test(c:match("%a"))
end)
local isLetter = isAlpha
local isAlphaNum = (sign(cb))(function(c)
  return test(c:match("%w"))
end)
local isPrint = (sign(cb))(function(c)
  return test(c:match("[^%z%c]"))
end)
local isDigit = (sign(cb))(function(c)
  return test(c:match("%d"))
end)
local isOctDigit = (sign(cb))(function(c)
  return test(c:match("[0-7]"))
end)
local isHexDigit = (sign(cb))(function(c)
  return test(c:match("%x"))
end)
local isPunctuation = (sign(cb))(function(c)
  return test(c:match("%p"))
end)
local toUpper = (sign(cc))(function(c)
  return {
    c = upper()
  }
end)
local toLower = (sign(cc))(function(c)
  return {
    c = lower()
  }
end)
local digitToNum = (sign("char -> number"))(function(c)
  return tonumber(c)
end)
local numToDigit = (sign("number -> char"))(function(c)
  return Char(tostring(c))
end)
return {
  char_resolver = char_resolver,
  Char = Char,
  isChar = isChar,
  isControl = isControl,
  isSpace = isSpace,
  isLower = isLower,
  isUpper = isUpper,
  isAlpha = isAlpha,
  isLetter = isLetter,
  isAlphaNum = isAlphaNum,
  isPrint = isPrint,
  isDigit = isDigit,
  isOctDigit = isOctDigit,
  isHexDigit = isHexDigit,
  isPunctuation = isPunctuation,
  toUpper = toUpper,
  toLower = toLower,
  digitToNum = digitToNum,
  numToDigit = numToDigit
}
