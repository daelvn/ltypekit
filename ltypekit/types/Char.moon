--> # ltypekit/types/Char
--> `Char` type in Lua.
-- 24.12.2018
-- By daelvn
import sign   from require "ltypekit"
import typeof from require "ltypekit.type"

--> # Using the type
--> This section describes the usage of the `Char` type in your code,
--> using ltypekit.
--> ## Registering the type
--> To register the type, you will need to import the resolver, name and library.
--> You can do this easily using ltypekit.type's functions:
--> ```moon
--> import typeof, libfor from require "ltypekit.type"
--> CharL = require "ltypekit.types.Char"
--> import CharT from CharL
--> -- Import the type first
--> typeof\import CharT, CharL

--> ## char_resolver
--> This is the code for the `Char` type used across all the codebase.
--> It is simply a checker for 1-long strings.
char_resolver = (any) -> if ((type any) == "string") and any\len! == 1 then "char" else false
typeof\add "char", char_resolver


--> ## Char
--> Creates an instance of a Char.
Char = sign "[string|char] -> char"
Char (c) -> c\sub 1,1

--> Preset signatures
ab = "* -> boolean"
cb = "char -> boolean"
cc = "char -> char"

--> # Testers
--> These functions test the kind of character. Primarily made for lbuilder3.

--> ## test
--> Checks that the returned values are truthy
test = (sign ab) (any) -> if any then true else false
--> ## isChar
--> Returns true if the value passed is a Char
isChar = (sign ab) (any) -> (char_resolver any) == "char"
--> ## isControl
--> Selects control characters.
isControl = (sign cb) (c) -> test c\match "%c"
--> ## isSpace
--> Returns `true` for any space character, and the control characters \t, \n, \r, \f, \v.
isSpace = (sign cb) (c) -> test c\match "%s"
--> ## isLower
--> Selects lower-case alphabetic characters (letters).
isLower = (sign cb) (c) -> test c\match "%l"
--> ## isUpper
--> Selects upper-case or title-case alphabetic characters (letters). Title case is used by a small number of letter ligatures like the single-character form of Lj.
isUpper = (sign cb) (c) -> test c\match "%u"
--> ## isAlpha
--> Selects alphabetic characters (lower-case, upper-case and title-case letters, plus letters of caseless scripts and modifiers letters). This function is equivalent to isLetter.
isAlpha  = (sign cb) (c) -> test c\match "%a"
isLetter = isAlpha
--> ## isAlphaNum
--> Selects alphabetic or numeric characters.
isAlphaNum = (sign cb) (c) -> test c\match "%w"
--> ## isPrint
--> Selects printable characters (letters, numbers, marks, punctuation, symbols and spaces).
isPrint = (sign cb) (c) -> test c\match "[^%z%c]"
--> ## isDigit
--> Selects ASCII digits, i.e. '0'..'9'.
isDigit = (sign cb) (c) -> test c\match "%d"
--> ## isOctDigit
--> Selects ASCII octal digits, i.e. '0'..'7'.
isOctDigit = (sign cb) (c) -> test c\match "[0-7]"
--> ## isHexDigit
--> Selects ASCII hexadecimal digits, i.e. '0'..'9', 'a'..'f', 'A'..'F'.
isHexDigit = (sign cb) (c) -> test c\match "%x"
--> ## isPunctuation
--> Selects punctuation characters, including various kinds of connectors, brackets and quotes.
isPunctuation = (sign cb) (c) -> test c\match "%p"

--> # Case conversion
--> Convert from lower to upper and viceversa.

--> ## toUpper
--> Converts the character to uppercase.
toUpper = (sign cc) (c) -> c:upper!
--> ## toLower
--> Converts the character to lowercase.
toLower = (sign cc) (c) -> c:lower!

--> # Type conversion
--> Converts across types. As of now, it only converts from and to `number`

--> ## digitToNum
--> Converts the character into a number.
digitToNum = (sign "char -> number") (c) -> tonumber c
--> ## numToDigit
--> Converts the number into a `char`.
numToDigit = (sign "number -> char") (c) -> Char tostring c

local CharT
--> ## CharL
--> Library for the `Char` type
CharL = {
  :char_resolver, :Char, :CharT, :isChar
  :isControl, :isSpace, :isLower, :isUpper, :isAlpha, :isLetter
  :isAlphaNum, :isPrint, :isDigit, :isOctDigit, :isHexDigit
  :isPunctuation
  :toUpper, :toLower
  :digitToNum, :numToDigit
}
--> ## CharT
--> Importable type for ltypekit.
CharT = {resolver: char_resolver, type: "char", lib: "CharL"}
--> ## Export
typeof\set_library "char", CharL
CharL
