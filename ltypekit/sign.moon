-- ltypekit | 19.12.2018
-- By daelvn
-- Signed functions as a unified type
-- Added generic support
import binarize, compare   from require "ltypekit.signature"
import type                from require "ltypekit.type"
import warn, die, contains from require "ltypekit.util"

local sign

apply_arguments = (argl) =>
  SIG = {signature: @_signature}
  
  parameters = {}

  warn_ = warn
  warn  = (s) ->
    if @safe       then die SIG, s
    if not @silent then warn_ s

  argn  = #@_tree.in
  if #argl > argn
    warn "There are more arguments than specified in the signature. Expected #{argn}, got #{#argl}"
  
  -- Collect input
  arg_i = {}
  for i=1, argn
    matchable = ((@._type @_tree.in[i]) == "string") and true or false
    if matchable and @_tree.in[i]\match "%->"
      -- Requests a signed function
      if (@._type argl[i]) == "signed"
        if argl[i]._signature == @_tree.in[i]
          table.insert arg_i, argl[i]
        else
          -- Do a rcompare, for it could have *, ! or another generic
          if compare argl[i]._signature, @_tree.in[i], @safe, @silent
            table.insert arg_i, argl[i]
          else
            die SIG, "Wrong type for argument ##{i}. Expected (#{@_tree.in[i]}), got (#{argl[i]._signature})"
      else
        die SIG, "Wrong type for argument ##{i}. Expected a signed function, got #{@._type argl[i]}"
    elseif matchable and @_tree.in[i]\match "%*"
      -- Any type
      table.insert arg_i, argl[i]
    elseif matchable and @_tree.in[i]\match "%!"
      -- Any type but nil
      if argl[i] != nil
        arg_i, argl[i]
      else
        die SIG, "Wrong type for argument ##{i}. Expected any value, got nil."
    elseif contains @_type.types, @_tree.in[i]
      -- Simple types
      if (@._type argl[i]) == @_tree.in[i]
        table.insert arg_i, argl[i]
      else
        die SIG, "Wrong type for argument ##{i}. Expected #{@_tree.in[i]}, got #{@._type argl[i]}"
    elseif ((@._type @_tree.in[i]) == "table") and (@_tree.in[i][1] == 0)
      -- Union
      didset = false
      for type_ in *@_tree.in[i][2,]
        if (@._type argl[i]) == type_ then didset = true
      if didset
        table.insert arg_i, argl[i]
      else
        die SIG, "Wrong type for argument ##{i}. Expected matching type in union, got #{@._type argl[i]}"
    elseif ((@._type @_tree.in[i]) == "table") and (@_tree.in[i][1] == 1)
      -- Generic
      if parameters[@_tree.in[i][2]]
        didset = false
        for type_ in *parameters[@_tree.in[i][2]][3,]
          if (@._type argl[i]) == type_ then didset = true
        if didset
          table.insert arg_i, argl[i]
        else
          die SIG, "Wrong type for argument ##{i}. Expected matching type in generic, got #{@._type argl[i]}"
      else
        parameters[@_tree.in[i][2]] = @_tree.in[i]
        didset                 = false
        for type_ in *parameters[@_tree.in[i][2]][3,]
          if (@._type argl[i]) == type_ then didset = true
        if didset
          table.insert arg_i, argl[i]
        else
          die SIG, "Wrong type for argument ##{i}. Expected matching type in generic, got #{@._type argl[i]}"
    else
      -- Parameter
      if parameters[@_tree.in[i]]
        if (parameters[@_tree.in[i]] == @._type argl[i])
          table.insert arg_i, argl[i]
        else
          die SIG, "Wrong type for argument ##{i}. Expected #{parameters[@_tree.in[i]]}, got #{@._type argl[i]}"
      else
        parameters[@_tree.in[i]] = @._type argl[i]
        table.insert arg_i, argl[i]

  -- Call function
  arg_m = {@._function (unpack or table.unpack) arg_i}
  -- Collect output
  argn  = #@_tree.out
  arg_o = {}

  for i=1, argn
    matchable = ((@._type @_tree.out[i]) == "string") and true or false
    if matchable and @_tree.out[i]\match "%->"
      -- Requests a signed function
      if (@._type arg_m[i]) == "signed"
        if arg_m[i]._signature == @_tree.out[i]
          table.insert arg_o, arg_m[i]
        else
          -- Do a rcompare, for it could have *, ! or another generic
          if compare arg_m[i]._signature, @_tree.out[i], @safe, @silent
            table.insert arg_o, arg_m[i]
          else
            die SIG, "Wrong type for return value ##{i}. Expected (#{@_tree.out[i]}), got (#{arg_m[i]._signature})"
      elseif (@._type arg_m[i]) == "function"
        warn "Automatically signing right side. This might have unintended side consequences."
        f = (sign @_tree.out[i]) arg_m[i]
        table.insert arg_o, arg_m[i]
      else
        die SIG, "Wrong type for return value ##{i}. Expected a signed function, got #{@._type arg_m[i]}"
    elseif matchable and @_tree.out[i]\match "%*"
      -- Any type
      table.insert arg_o, arg_m[i]
    elseif matchable and @_tree.out[i]\match "%!"
      -- Any type but nil
      if arg_m[i] != nil
        arg_o, arg_m[i]
      else
        die SIG, "Wrong type for return value ##{i}. Expected any value, got nil."
    elseif contains @_type.types, @_tree.out[i]
      -- Simple types
      if (@._type arg_m[i]) == @_tree.out[i]
        table.insert arg_o, arg_m[i]
      else
        die SIG, "Wrong type for return value ##{i}. Expected #{@_tree.out[i]}, got #{@._type arg_m[i]}"
    elseif ((@._type @_tree.out[i]) == "table") and (@_tree.out[i][1] == 0)
      -- Union
      didset = false
      for type_ in *@_tree.out[i][2,]
        if (@._type arg_m[i]) == type_ then didset = true
      if didset
        table.insert arg_o, arg_m[i]
      else
        die SIG, "Wrong type for return value ##{i}. Expected matching type in union, got #{@._type arg_m[i]}"
    elseif ((@._type @_tree.out[i]) == "table") and (@_tree.out[i][1] == 1)
      -- Generic
      if parameters[@_tree.out[i][2]]
        didset = false
        for type_ in *parameters[@_tree.out[i][2]][3,]
          if (@._type arg_m[i]) == type_ then didset = true
        if didset
          table.insert arg_o, arg_m[i]
        else
          die SIG, "Wrong type for return value ##{i}. Expected matching type in generic, got #{@._type arg_m[i]}"
      else
        parameters[@_tree.out[i][2]] = @_tree.out[i]
        didset                 = false
        for type_ in *parameters[@_tree.out[i][2]][3,]
          if (@._type arg_m[i]) == type_ then didset = true
        if didset
          table.insert arg_o, arg_m[i]
        else
          die SIG, "Wrong type for return value ##{i}. Expected matching type in generic, got #{@._type arg_m[i]}"
    else
      -- Parameter
      if parameters[@_tree.out[i]]
        if (parameters[@_tree.out[i]] == @._type arg_m[i])
          table.insert arg_o, arg_m[i]
        else
          die SIG, "Wrong type for return value ##{i}. Expected #{parameters[@_tree.out[i]]}, got #{@._type arg_m[i]}"
      else
        parameters[@_tree.out[i]] = @._type arg_m[i]
        table.insert arg_o, arg_m[i]

  return (unpack or table.unpack) arg_o

sign = (signature) -> setmetatable {
  _signature: signature
  _tree:      rbinarize signature
  _type:      type
  _function:  ->
  safe:       false
  silent:     true
}, {
  __type: "signed_constructor"
  __add:  (resolver) =>
    table.insert @_type.resolvers, resolver
    return @
  __sub: (types) =>
    for type_ in *types do table.insert @_type.types, type_
    return @

  -- For type signed*
  __call: (...) =>
    argl = {...}

    if (getmetatable @).__type == "signed_constructor"
      @._function             = argl[1]
      (getmetatable @).__type = "signed"
      return @

    return apply_arguments @, argl
}

{ :sign }
