-- ltypekit | 14.12.2018
-- By daelvn
-- Signed functions as a unified type
import binarize, compare   from require "ltypekit.signature"
import type                from require "ltypekit.type"
import warn, die, contains from require "ltypekit.util"

sign = (signature) -> setmetatable {
  _signature: signature
  _tree:      binarize signature
  _type:      type
  _function:  ->
  safe:       false
  silent:     true
}, {
  -- For type signed_constructor
  __type: "signed_constructor"
  __add:  (resolver) =>
    table.insert @_type.resolvers, resolver
    return @
  __sub:  (types) =>
    for type_ in *types do table.insert @_type.types, type_
    return @

  -- For type signed*
  __call: (...) =>
    SIG = {signature: @_signature}
    argl = {...}

    -- In the case we have no function assigned
    if (getmetatable @).__type == "signed_constructor"
      @._function             = argl[1]
      (getmetatable @).__type = "signed"
      return @

    warn_ = warn
    warn  = (s) ->
      if safe       then die SIG, s
      if not silent then warn_ s

    argn    = #@_tree.in
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
            if compare argl[i]._signature, @_tree.in[i], safe, silent
              table.insert arg_i, argl[i]
            else
              die SIG, "Wrong type for argument ##{i}. Expected (#{@_tree.in[i]}), got (#{argl[i]._signature})"
        else die SIG, "Wrong type for argument ##{i}. Expected a signed function, got #{@._type argl[i]}"
      elseif @_tree.in[i]\match "%*"
        -- Any type
        table.insert arg_i, argl[i]
      elseif @_tree.in[i]\match "%!"
        -- Any but nil
        if argl[i] != nil
          table.insert arg_i, argl[i]
        else
          --printi {:argn, :argl, :arg_i, :holders, tree: @_tree}
          die SIG, "Wrong type for argument ##{i}. Expected any value, got nil"
      elseif contains @._type.types, @_tree.in[i]
        -- Recognized type
        if (@._type argl[i]) == @_tree.in[i]
          table.insert arg_i, argl[i]
        else
          die SIG, "Wrong type for argument ##{i}. Expected #{@_tree.in[i]}, got #{@._type argl[i]}."
      else
        -- Placeholder
        if holders[@_tree.in[i]]
          if (holders[@_tree.in[i]] == @._type argl[i])
            table.insert arg_i, argl[i]
          else
            die SIG, "Wrong type for argument ##{i}. Expected #{holders[@_tree.in[i]]}, got #{@._type argl[i]}"
        else
          holders[@_tree.in[i]] = @._type argl[i]
          table.insert arg_i, argl[i]
    
    -- Call function
    arg_m = {@._function (unpack or table.unpack) arg_i}

    -- Collect output
    argn  = #@_tree.out
    arg_o = {}
    for i=1,argn
      if @_tree.out[i]\match "%->"
        -- Requests a signed function
        if (@._type arg_m[i]) == "signed"
          if arg_m[i]._signature == @_tree.out[i]
            table.insert arg_o, arg_m[i]
          else die SIG, "Wrong type for return value ##{i}. Expected (#{@_tree.out[i]}), got (#{arg_m[i]._signature})"
        else
          if (@._type arg_m[i]) == "function"
            warn "Automatically signing right side. This might have unintended side consequences."
            f = (sign @_tree.out[i]) arg_m[i]
            table.insert arg_o, arg_m[i]
          else
            die SIG, "Wrong type for return value ##{i}. Expected a signed function, got #{@._type arg_m[i]}"
      elseif @_tree.out[i]\match "%*"
        -- Any type
        table.insert arg_o, arg_m[i]
      elseif @_tree.out[i]\match "%!"
        -- Any but nil
        if arg_m[i] != nil
          table.insert arg_o, arg_m[i]
        else
          die SIG, "Wrong type for return value ##{i}. Expected any value, got nil"
      elseif contains @._type.types, @_tree.out[i]
        -- Recognized type
        if (@._type arg_m[i]) == @_tree.out[i]
          table.insert arg_o, arg_m[i]
        else
          die SIG, "Wrong type for return value ##{i}. Expected #{@_tree.out[i]}, got #{@._type arg_m[i]}"
      else
        -- Placeholder
        if holders[@_tree.out[i]]
          if (holders[@_tree.out[i]] == @._type arg_m[i])
            table.insert arg_o, arg_m[i]
          else
            die SIG, "Wrong type for return value ##{i}. Expected #{holders[@_tree.out[i]]}, got #{@._type arg_m[i]}"
        else
          holders[@_tree.out[i]] = @._type argl[i]
          table.insert arg_o, arg_m[i]

    return (unpack or table.unpack) arg_o
}

{ :sign }
