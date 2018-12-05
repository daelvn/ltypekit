package = "ltype"
version = "1.1-1"

source  = {
  url   = "https://github.com/daelvn/ltype",
  tag   = "v1.1"
}

description = {
  summary  = "Advanced typechecker for Lua",
  detailed = [[
    This advanced type checking system supports function signatures,
    and has a custom type function that supports custom types.
  ]],
  homepage = "https://github.com/daelvn/ltype",
  license  = "MIT/X11"
}

dependencies = {
  "lua"
}

build = {
  type    = "builtin",
  modules = {
    ["ltype.init"]      = "ltype/init.lua",
    ["ltype.signature"] = "ltype/signature.lua",
    ["ltype.type"]      = "ltype/type.lua",
    ["ltype.util"]      = "ltype/util.lua",
    ["ltype.wrap"]      = "ltype/wrap.lua"
  },
}
