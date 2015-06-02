module Test_Modifyfield

using Modifyfield

immutable TestT
    intfld::Int
    boolfld::Bool
end


function testmodifyfield()
    n = 3
    a = Array(TestT,n)
    b = Array(TestT,n,n)
    for i = 1 : n
        a[i] = TestT(i,false)
        for j = 1 : n
            b[i,j] = TestT(j,true)
        end
    end
    for i = 1 : n
        @modify_field! a[i].intfld = i - 1
    end
    for i = 1 : n
        @assert a[i].intfld == i - 1 && a[i].boolfld == false
    end
    for i = 1 : n
        for j = 1 : n
            @modify_field! b[i,j].boolfld = false
        end
    end
    for i = 1 : n
        for j = 1 : n
            @assert b[i,j].intfld == j && b[i,j].boolfld == false
        end
    end
    nothing
end

function testmodifytuple()
    t = (5.5, 6.6, 7.7)
    @modify_tuple_entry! t[2] = true
    @assert t == (5.5, true, 7.7)
    @modify_tuple_entry! t[3] = "a"
    @assert t == (5.5, true, "a")
    @modify_tuple_entry! t[1] = Int
    @assert t == (Int, true, "a")
    n = 10
    a = (Array{Tuple{Int,Int},1})[]
    for j = 1 : n
        a[j] = (j,j)
    end
    for j = 1 : n
        @modify_tuple_entry! a[j][2] = j*j
    end
    for j = 1 : n
        @assert a[j][1] == j && a[j][2] == j*j
    end
    nothing
end

println("starting tests...")
testmodifyfield()
testmodifytuple()
println("tests finished")

end



