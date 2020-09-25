# ConcreteStructs.jl

[![Build Status](https://img.shields.io/travis/com/jonniedie/ConcreteStructs.jl)](https://travis-ci.com/jonniedie/ConcreteStructs.jl)
[![codecov](https://img.shields.io/codecov/c/gh/jonniedie/ConcreteStructs.jl?label=codecov&logo=codecov)](https://codecov.io/gh/jonniedie/ConcreteStructs.jl)

ConcreteStructs.jl exports the macro `@concrete`, which can be used to make non-concrete structs
concrete without the boilerplate of adding type parameters.

```julia
using ConcreteStructs

@concrete struct AB
    a
    b
end
```
```julia-repl
julia> ab = AB("hi", 1+im)
AB{String,Complex{Int64}}("hi", 1 + 1im)
```
 The macro also supports the `terse` keyword to allow the types to show without their parameters while in `:compact => true` mode of an `IOContext`.
```julia
@concrete terse mutable struct CDE{D} <: Number
    d::D
    c
    e::Symbol
end
```
```julia-repl
julia> cde = CDE(1f0, (1,2.0), :yo)
CDE(1.0f0, (1, 2.0), :yo)

julia> typeof(cde)
CDE{Float32,Tuple{Int64,Float64}}
```
Types with more complicated parameterizations are also handled
```julia
@concrete terse struct FGH{T,N,G<:AbstractArray{T,N}} <: AbstractArray{T,N}
    g::G
    h::T
    f
    function FGH(g::AbstractArray{T,N}, h::H, f) where {T,N,H}
        Tnew = promote_type(T, H)
        g, h = Tnew.(g), Tnew(h)
        return new{Tnew,N,typeof(g),typeof(f)}(g, h, f)
    end
end

Base.size(x::FGH) = size(x.g)

Base.getindex(x::FGH, i...) = getindex(x.g[i...])
```
```julia-repl
julia> fgh = FGH([1,2,3], 4, nothing)
3-element FGH:
 1
 2
 3

julia> typeof(fgh)
FGH{Int64,1,Array{Int64,1},Nothing}
```
