-- ltype | 23.11.2018
-- By daelvn
-- Wrap a function to use type signatures
import binarize, compare   from require "ltype.signature"
import type                from require "ltype.type"
import warn, die, contains from require "ltype.util"

local signature, callable

-- Type checking goes here
callable = (f, sig, typef, safe, silent) -> setmetatable {
  _type:      typef
  _signature: sig
  _tree:      binarize sig
  :safe
  :silent
}, {
  __type: "signed"
  __call: (...) =>
    warn_ = warn
    warn  = (s) ->
      if safe       then die s
      if not silent then warn_ s
    argn    = #@_tree.in
    argl    = {...}
    arg_i   = {}
    holders = {}
    if #argl > argn then warn "There are more arguments than specified in the signature. Expected #{argn}, got #{#argl}"
    -- Collect input
    for i=1,argn
      if @_tree.in[i]\match "%->"
        -- Requests a signed function
        if (@._type argl[i]) == "signed"
          if argl[i]._signature == @_tree.in[i]
            table.insert arg_i, argl[i]
          else
            -- Could have * or !
            if compare argl[i]._signature, @_tree.in[i]
              table.insert arg_i, argl[i]
            else
              die "Wrong type for argument ##{i}. Expected (#{@_tree.in[i]}), got (#{argl[i]._signature})"
        else die "Wrong type for argument ##{i}. Expected a signed function, got #{@._type argl[i]}"
      elseif @_tree.in[i]\match "%*"
        -- Any type
        table.insert arg_i, argl[i]
      elseif @_tree.in[i]\match "%!"
        -- Any but nil
        if argl[i] != nil
          table.insert arg_i, argl[i]
        else
          --printi {:argn, :argl, :arg_i, :holders, tree: @_tree}
          die "Wrong type for argument ##{i}. Expected any value, got nil"
      elseif contains @._type.types, @_tree.in[i]
        -- Recognized type
        if (@._type argl[i]) == @_tree.in[i]
          table.insert arg_i, argl[i]
        else
          die "Wrong type for argument ##{i}. Expected #{@_tree.in[i]}, got #{@._type argl[i]}."
      else
        -- Placeholder
        if holders[@_tree.in[i]]
          if (holders[@_tree.in[i]] == @._type argl[i])
            table.insert arg_i, argl[i]
          else
            die "Wrong type for argument ##{i}. Expected #{holders[@_tree.in[i]]}, got #{@._type argl[i]}"
        else
          holders[@_tree.in[i]] = @._type argl[i]
          table.insert arg_i, argl[i]
    
    -- Call function
    arg_m = {f (unpack or table.unpack) arg_i}

    -- Collect output
    argn  = #@_tree.out
    arg_o = {}
    for i=1,argn
      if @_tree.out[i]\match "%->"
        -- Requests a signed function
        if (@._type arg_m[i]) == "signed"
          if arg_m[i]._signature == @_tree.out[i]
            table.insert arg_o, arg_m[i]
          else die "Wrong type for return value ##{i}. Expected (#{@_tree.out[i]}), got (#{arg_m[i]._signature})"
        else
          if (@._type arg_m[i]) == "function"
            warn "Automatically signing right side. This might have unintended side consequences."
            f = (signature @_tree.out[i]) arg_m[i]
            table.insert arg_o, arg_m[i]
          else
            die "Wrong type for return value ##{i}. Expected a signed function, got #{@._type arg_m[i]}"
      elseif @_tree.out[i]\match "%*"
        -- Any type
        table.insert arg_o, arg_m[i]
      elseif @_tree.out[i]\match "%!"
        -- Any but nil
        if arg_m[i] != nil
          table.insert arg_o, arg_m[i]
        else
          die "Wrong type for return value ##{i}. Expected any value, got nil"
      elseif contains @._type.types, @_tree.out[i]
        -- Recognized type
        if (@._type arg_m[i]) == @_tree.out[i]
          table.insert arg_o, arg_m[i]
        else
          die "Wrong type for return value ##{i}. Expected #{@_tree.out[i]}, got #{@._type arg_m[i]}"
      else
        -- Placeholder
        if holders[@_tree.out[i]]
          if (holders[@_tree.out[i]] == @._type arg_m[i])
            table.insert arg_o, arg_m[i]
          else
            die "Wrong type for return value ##{i}. Expected #{holders[@_tree.out[i]]}, got #{@._type arg_m[i]}"
        else
          holders[@_tree.out[i]] = @._type argl[i]
          table.insert arg_o, arg_m[i]

    return (unpack or table.unpack) arg_o
}

-- Signature parsing goes here
signature = (sig) -> setmetatable {
  _signature: sig
  _type:      type
  safe:       false
  silent:     true
}, {
  __type: "signed_constructor"
  __add:  (resolver) =>
    table.insert @._type.resolvers, resolver
    return @
  __sub: (typet) =>
    for type_ in *typet do table.insert @._type.types, type_
    return @
  __call: (f)    => callable f, @_signature, @._type, @safe, @silent
}

{:signature}
