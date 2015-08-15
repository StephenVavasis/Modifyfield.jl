module Modifyfield



@generated function copy_and_modify{fieldname}(x, ::Type{Val{fieldname}}, newval)
    F = fieldnames(x)
    mask = F .== fieldname
    if sum([convert(Int,mask[j]) for j = 1 : length(mask)]) != 1
        error("Type $x does not have a field $fieldname")
    end
    D = Any[:(x.$f) for f in F]
    D[mask] = :newval
    Expr(:call, x, D...)
end


@generated function copy_and_modify_mult{tupfieldnames}(x, 
                                                        ::Type{Val{tupfieldnames}},
                                                        newvals...)
    F = fieldnames(x)
    D = Any[:(x.$f) for f in F]
    for (pos,fn) in enumerate(tupfieldnames)
        mask = F .== fn
        if sum([convert(Int,mask[j]) for j = 1 : length(mask)]) != 1
            error("Type $x does not have a field $fn")
        end
        D[mask] = :(newvals[$pos])
    end
    Expr(:call, x, D...)
end

macro modify_fields!(ex)
    ex.head == :(.) && ex.args[2].head == :tuple || error("Invalid usage of @modify_fields! macro")
    lhs = ex.args[1]
    arrfieldnames = Any[]
    newvals = Any[]
    for assn in ex.args[2].args
        assn.head == :(=) || error("Invalid usage of @modify_fields! macro")
        push!(arrfieldnames, Symbol(assn.args[1]))
        push!(newvals, assn.args[2])
    end
    # generate an expression like:
    #  lhs = copy_and_modifymult(lhs, Val{(fieldname1,fieldname2,...), newval1,
    #                            newval2, ...)
    # Do it the long way because I couldn't figure out where to put the
    # esc calls and ...'s.
    res = Expr(:(=))
    push!(res.args, lhs)
    push!(res.args, Expr(:call))
    callargs = res.args[2].args
    push!(callargs, :copy_and_modify_mult)
    push!(callargs, lhs)
    push!(callargs, Expr(:curly))
    curlyargs = callargs[3].args
    push!(curlyargs, :Val)
    push!(curlyargs, Expr(:tuple))
    for fn in arrfieldnames
        push!(curlyargs[2].args, QuoteNode(fn))
    end
    for nv in newvals
        push!(callargs, nv)
    end
    esc(res)
end

        

macro modify_field!(ex)
    ex.head == :(=) && ex.args[1].head == :(.) || error("Invalid usage of @modify_field! macro")
    lhs, newval = ex.args
    x, g = lhs.args
    esc(:($x = copy_and_modify($x, Val{$g}, $newval)))
    # :($(esc(x)) = copy_and_modify($(esc(x)), Val{$g}, $(esc(newval))))
end

@generated function copy_and_modify_tup{N,i}(x::NTuple{N}, ::Type{Val{i}}, newval)
    (i < 1 || i > N) && error("Tuple subscript $i is out of range for length-$N tuple")
    D = Any[:(x[$j]) for j = 1 : N]
    D[i] = :newval
    Expr(:tuple, D...)
end

macro modify_tuple_entry!(ex)
    ex.head == :(=) && ex.args[1].head == :ref || error("Invalid usage of @modify_tuple_entry! macro")
    lhs, newval = ex.args
    x, sub = lhs.args
    #:($(esc(x)) = copy_and_modify_tup($(esc(x)), Val{$sub}, $(esc(newval))))
    esc(:($x = copy_and_modify_tup($x, Val{$sub}, $newval)))
end


export copy_and_modify,
  copy_and_modify_mult,
  copy_and_modify_tup,
  @modify_field!,
  @modify_tuple_entry!


end
