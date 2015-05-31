module Modifyfield

copyandmodify() = nothing
modifyField!() = nothing

function convertNestedToExpr(nested)
    if isa(nested, Expr) || isa(nested, QuoteNode) || 
        isa(nested, Symbol) || isa(nested,DataType)
        nested
    else
        e = Expr(nested[1])
        for item in nested[2]
            push!(e.args, convertNestedToExpr(item))
        end
        e
    end
end


function makecopyandmodify(T::DataType)
    global copyandmodify
    names = fieldnames(T)
    ln = length(names)
    for (count,fname) in enumerate(names)

        #The following statement evaluates an expression like the following:
        # copyandmodify(x::T, Type{Val{fieldname}},newval) = T(x.field1, x.field2,...
        #                x.field_{k-1}, newval, x.field_{k+1},...,x.fieldn)
        # In other words, this expression creates a statement function
        # named copyandmodify


        eval(convertNestedToExpr((:(=),
                                  [(:call,
                                    [:copyandmodify,
                                     :(x::$T),
                                     (:(::), 
                                      [(:curly,
                                        [:Type,
                                         (:curly,
                                          [:Val, QuoteNode(fname)])])]),
                                     :newval]),
                                   (:call,
                                    [[T] ;
                                     [(:., 
                                       [:x, QuoteNode(fname1)])
                                        for fname1 in names[1:count-1]] ;
                                     [:newval] ;
                                     [(:., [:x, QuoteNode(fname1)])
                                            for fname1 in names[count+1:ln]]])])))

    end
    nothing
end




function makemodifyfield(T::DataType, Container::DataType, numsub::Int)
    global modifyField!
    names = fieldnames(T)
    for fname in names

        # This statement defines a function of the following form:
        # function modifyField!(a::Container, sub1, sub2, ..., subk, Type{Val{:fname)}, newval)
        #   a[sub1, sub2, ..., subk] = copyandmodify(a[sub1, sub2, ..., subk],
        #                                            Val{:fname), newval)
        #   nothing
        # end




        eval(convertNestedToExpr((:function,
                                  [(:call, 
                                    [[:modifyField!,
                                      :(a::$Container)] ;
                                     [symbol("sub"*string(k)) for k=1:numsub] ;
                                     [(:(::), 
                                       [(:curly,
                                         [:Type,
                                          (:curly,
                                           [:Val, QuoteNode(fname)])])])] ;
                                     [:newval]]),
                                   (:block,
                                    [(:(=),
                                      [(:ref,
                                        [[:a];
                                         [symbol("sub"*string(k)) for k=1:numsub]]),
                                       (:call,
                                        [:copyandmodify,
                                         (:ref,
                                          [[:a];
                                           [symbol("sub"*string(k)) for k=1:numsub]]),
                                         (:curly,
                                          [:Val, QuoteNode(fname)]),
                                         :newval])]),
                                     :nothing])])))
    end
    nothing
end

export makecopyandmodify
export makemodifyfield
export copyandmodify
export modifyField!

end
