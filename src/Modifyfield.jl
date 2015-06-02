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

macro modify_field!(ex)
    ex.head == :(=) && ex.args[1].head == :(.) || error("Invalid usage of @modify_field! macro")
    lhs, newval = ex.args
    x, g = lhs.args
    :($(esc(x)) = copy_and_modify($(esc(x)), Val{$g}, $(esc(newval))))
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
    :($(esc(x)) = copy_and_modify_tup($(esc(x)), Val{$sub}, $(esc(newval))))
end


export copy_and_modify,
  copy_and_modify_tup,
  @modify_field!,
  @modify_tuple_entry!


end
