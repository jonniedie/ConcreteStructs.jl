using ConcreteStructs
using Suppressor
using Test


@concrete struct Plain end
plain = Plain()

@concrete struct Args
    a
    b
end
args = Args(1+im, "hi")

@concrete mutable struct SubtypedMutable <: Number
    a
    b
end
subtyped_mutable = SubtypedMutable(3.0, 4f0)

@concrete struct Partial{A}
    a::A
    b
end
partial = Partial(:yo, 1//2)

@concrete mutable struct ConstructorMutable{A,C}
    a::A
    b
    c::C
    ConstructorMutable(a::A, b, c::C) where {A,C} = new{A,C,typeof(b)}(a, b, c)
end
constructor_mutable = ConstructorMutable([1.0+im, 2], 'r', (2,))
constructor_mutable.b = 'h'

@concrete terse struct TerseSameType{A}
    a::A
    b::A
    function TerseSameType(a::A, b::B) where {A,B}
        T = promote_type(A, B)
        return new{T}(T(a), T(b))
    end
end
terse_same_type = TerseSameType(1+im, 5f0)

@concrete terse struct FullyParameterized{B}
    a::Symbol
    b::B
    FullyParameterized(a, b) = new{typeof(b)}(a, b)
end
fully_parameterized = FullyParameterized(:sine, sin)

@concrete mutable struct ParameterizedSubtyped{T,N,B<:AbstractArray{T,N}} <: AbstractArray{T,N}
    a
    b::B
    c::T
end
parameterized_subtyped = ParameterizedSubtyped(:🏦, [1, 2, 3], 4)




@testset "ConcreteStructs.jl" begin
    @test_throws ErrorException args.a = 2+im
    @test_throws MethodError subtyped_mutable.a = "hi"
    @test_throws InexactError constructor_mutable.c = (1.5,)

    @test typeof(partial) |> isconcretetype
    @test typeof(terse_same_type.a) === typeof(terse_same_type.b)
    @test typeof(fully_parameterized.a) |> isconcretetype
    @test eltype(parameterized_subtyped.b) === typeof(parameterized_subtyped.c)

    @test @capture_out(show(stdout, MIME("text/plain"), typeof(fully_parameterized))) == "FullyParameterized{typeof(sin)}"
    @test @capture_out(show(stdout, fully_parameterized)) == "FullyParameterized(:sine, sin)"
end
