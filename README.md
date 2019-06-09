<p center="align">
  <img src=".github/ltypekit.logo.png">
<p/>

# ltypekit

Advanced type checking library for Lua and MoonScript.

---

`ltypekit` is a library born from the purpose of making typechecking easier. Sometimes you'll need several lines of:

```coffeescript
if (type a) == "string" then ...
if (type b) == "number" then ...
```

or even need more complex checks to see if you're getting passed the structure you need. `ltypekit` aims to solve this using the well-known concept of signatures, that certainly works better in statically typed languages like Haskell, but it does the job here. It is combined with a `typeof` function that extends the capability of [typical](https://github.com/hoelzro/lua-typical) or [mtype](https://github.com/jirutka/mtype). These `type` functions check for a `__type` metamethod and pass it back. `typeof`, however, works using the concept of *resolvers*. These are functions which check for specific conditions and return a certain value if it matches the type or not. This means you can add your own types and resolvers, and use libraries such as [tableshape](https://github.com/leafo/tableshape) so that you can use the full capability of this function. Signatures, in its current state, support nesting functions, unknowns, type variables and constraints, among others.

## Installing

You can install it via LuaRocks:

```
$ luarocks install ltypekit
```

Or, alternatively, you can install it for your project, unmanaged:

```
$ cp ./ltypekit/* ./lib/ltypekit/
```

## Importing

You can import it in your code as such:

```python
import sign   from require "ltypekit"
import typeof from require "ltypekit.type"
```

Or, in Lua:

```lua
local ltypekit = require "ltypekit"
ltypekit.type  = require "ltypekit.type"
local sign     = ltypekit.sign
local typeof   = ltypekit.type.typeof
```

## Usage

### typeof (ltypekit.type)

#### Resolvers

Resolvers are functions which take in any value and return something depending on whether it can resolve the type or not. Resolvers such as `has_meta` will return the string of the type. Others, such as IO, return a boolean value, since the type is guessed from the resolver function's name.

##### Issues with overlapping

You should make sure that your resolver *only* resolves your type, so that not all tables, for example, are marked as a "Collection" type. If your type is too simple to be easily confused (say, a bidimensional vector), you should consider creating a `__type` metamethod which gives the 2DVector value.

#### `typeof\add name, resolver`
Adds a raw type to typeof.

#### `typeof\new T`

Adds a type from a T object (template or type holder).

#### `typeof\resolve val, resolverl`

Returns the type for `val`, using the resolvers in `resolverl`. You will rarely have to use this function.

#### `typeof\resolves val`

Checks if `typeof` can resolve `a`, it will return `true` and the name of the type, otherwise just `false`. Bear in mind, this doesn't fallback to the native `type` method.

#### `typeof val`

Equivalent to `typeof\resolve`, but it wraps the `resolverl` so that you don't have to provide it.

### typeE (ltypekit.type)

Creates a type template, you can optionally pass to it a name (defaults to "?") and an annotation. These combined should form something like `Char str`

### data (ltypekit.type)

Creates a new, single type with several constructors using a simple resolver. It takes a type template `T` (or any table) and a definition table. It will also automatically test itself in case the constructor does not generate a valid type.

```lua
data Char
  name:         "Char"
  annotation:   "Char string"
  resolver:     (v) -> ((type v)=="string") and (#v==1)
  constructor:  (v) -> v\sub 1,1
  constructors: {Char}
```

### metatype (ltypekit.type)

Creates a constructor for any type (using `__type`)

```lua
Container = typeE "Container", "number string"
metatype Container, (n, s) -> {id: n, name: s}
typeof Container 5, "name" -- Container
```

### typeforall (ltypekit.type)

Checks that all the values in a list are of the same type. If so, it returns the type name, otherwise returns false.

### typeforany (ltypekit.type)

Returns all the possible types in a list.

### sign (ltypekit.init / ltypekit.sign)

Perhaps the most useful function of the whole library. It takes in a signature, and returns a `signed_constructor` value. This value has overloaded `+` and `-` metamethods, but these should be deprecated soon. You can make a function safe if you change `<constructor>.safe` to `true`, and so it will error in warnings. Contrary to that, you can change `<constructor>.silent` to `false` if you don't want any warnings to appear. `false` is default for `.safe` and `true` is default for `.silent`. Once you got that, you only have to pass a function to your constructor, and a `signed` value function will be created, which will work just as you would expect.

## Signatures

Signatures are currently different from those you'd see in Haskell (but I'm working to change that!). The basic functioning is:

```
string -> (a -> *) -> [c|b] -> a -> d<string> -> e<x|y>
^          ^  ^ ^     ^        ^    ^            ^
|          |  | |     |        |    |            Constraints
|          |  | |     |        |   A type cons-  can have
|          |  | |     |        |   traint        unions!
|          |  | |     |       a will be the same
|          |  | |     |       type across all the
|          |  | |     |       signature!
|          |  | |     Unions!
|          |  | * accepts any type and
|          |  | ! accepts all but nil
|          |  |
|          |  This does work! You can have functions
|          |  in the signature and they will, indeed
|          |  ask for a signed function.
|          |
|        Type variables!
Use type names to ask for those types.
```

## Other types

There is an extensive collection of types in the works. You can check out a small preview in the `ltypekit/types/` folder.

##  License

```
MIT License
Copyright 2019 Cristian Muñiz (daelvn)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
