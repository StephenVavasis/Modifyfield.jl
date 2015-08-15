using Base.test.@test
using Modifyfield
using Modifyfield.@modify_field!
using Modifyfield.@modify_fields!
using Modifyfield.@modify_tuple_entry!
using Modifyfield.copy_and_modify_tup

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
        @test a[i].intfld == i - 1 && a[i].boolfld == false
    end
    for i = 1 : n
        for j = 1 : n
            @modify_field! b[i,j].boolfld = false
        end
    end
    for i = 1 : n
        for j = 1 : n
            @test b[i,j].intfld == j && b[i,j].boolfld == false
        end
    end
    nothing
end

function testmodifytuple()
    t = (5.5, 6.6, 7.7)
    @modify_tuple_entry! t[2] = true
    @test t == (5.5, true, 7.7)
    @modify_tuple_entry! t[3] = "a"
    @test t == (5.5, true, "a")
    @modify_tuple_entry! t[1] = Int
    @test t == (Int, true, "a")
    n = 10
    a = (Tuple{Int,Int})[]
    resize!(a,n)
    for j = 1 : n
        a[j] = (j,j)
    end
    for j = 1 : n
        @modify_tuple_entry! a[j][2] = j*j
    end
    for j = 1 : n
        @test a[j][1] == j && a[j][2] == j*j
    end
    nothing
end

function testmodifytuple2()
    t = (0,1,2)
    for i = 1 : 3
        # The macro call
        # @modify_tuple_entry! t[i] = i
        # fails (variable subscript).
        #
        # The function-call variant in
        # the next statement is dispatched at
        # run time instead of compile time because
        # the type of Val{i} is unknown at
        # compile time.  This leads to poorer
        # performance.
        t = copy_and_modify_tup(t, Val{i}, i)  
    end
    @test t == (1,2,3)
    nothing
end

immutable TestT2
    a::Int
    b::Bool
    c::Float64
end

function testmodifyfields()
    v = TestT2[]
    push!(v, TestT2(4,false,65.2))
    push!(v, TestT2(3,true, 94.2))
    z = 64.5
    @modify_fields! v[1].(a=9,c=z+.5)
    @modify_fields! v[2].(c=z-0.5, b=false)
    @test v[1] == TestT2(9, false, 65.0)
    @test v[2] == TestT2(3, false, 64.0)
    @modify_fields! v[2].(a=-2,)
    @test v[2] == TestT2(-2, false, 64.0)
    nothing
end
    

println("starting tests...")
testmodifyfield()
testmodifytuple()
testmodifytuple2()
testmodifyfields()
println("tests finished")




