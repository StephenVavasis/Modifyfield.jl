using modifyfield

immutable TestT
    intfld::Int
    boolfld::Bool
end

makecopyandmodify(TestT)
makemodifyfield(TestT, Array{TestT,1}, 1)
makemodifyfield(TestT, Array{TestT,2}, 2)

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
        modifyField!(a, i, Val{:intfld}, i - 1)
    end
    for i = 1 : n
        @assert a[i].intfld == i - 1 && a[i].boolfld == false
    end
    for i = 1 : n
        for j = 1 : n
            modifyField!(b, i, j, Val{:boolfld}, false)
        end
    end
    for i = 1 : n
        for j = 1 : n
            @assert b[i,j].intfld == j && b[i,j].boolfld == false
        end
    end
end


