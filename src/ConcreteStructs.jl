"""
    ConcreteStructs

ConcreteStructs exports the macro `@concrete`, which can be used to make non-concrete structs
concrete.
"""
module ConcreteStructs


export @concrete


"""
    @concrete struct
    @concrete mutable struct
    @concrete terse struct
    @concrete terse mutable struct

The `@concrete` macro makes non-concrete structs concrete, saving the boilerplate of making
type parameters. The `terse` keyword causes the types to show without their parameters while
in `:compact => true` mode of an `IOContext`.

## Examples
```julia
julia> using ConcreteStructs

julia> @concrete struct AB
           a
           b
       end

julia> ab = AB("hi", 1+im)
AB{String,Complex{Int64}}("hi", 1 + 1im)

julia> @concrete terse mutable struct CDE{D} <: Number
            d::D
            c
            e::Symbol
        end

julia> cde = CDE(1f0, (1,2.0), :yo)
CDE(1.0f0, (1, 2.0), :yo)

julia> typeof(cde)
CDE{Float32,Tuple{Int64,Float64}}

julia> @concrete terse struct FGH{T,N,G<:AbstractArray{T,N}} <: AbstractArray{T,N}
           f
           g::G
           h::T
       end

julia> Base.size(x::FGH) = size(x.g); Base.getindex(x::FGH, i...) = getindex(x.g[i...])

julia> fgh = FGH(nothing, [1,2,3], 4)
3-element FGH:
 1
 2
 3

julia> typeof(fgh)
FGH{Int64,1,Array{Int64,1},Nothing}
```
"""
macro concrete(expr)
    return _make_concrete(expr) |> esc
end

macro concrete(terse, expr)
    terse isa Symbol && terse == :terse || error("Invalid usage of @concrete")
    expr = _make_concrete(expr)
    struct_name = expr.args[2].args[1].args[1]
    full_params = "{" * join(expr.args[2].args[1].args[2:end], ",") * "}"

    return quote
        $expr
        Base.show(io::IO, ::Type{<:$struct_name}) = print(io, $(string(struct_name)))
        function Base.show(io::IO, ::MIME"text/plain", T::Type{<:$struct_name})
            return print(io, $(string(struct_name)) * "{" * join(T.parameters, ",") * "}")
        end
    end |> esc
end


# Parse whole struct definition for the @concrete macro
function _make_concrete(expr)
    expr isa Expr && expr.head == :struct || error("Invalid usage of @concrete")

    maybe_mutable = expr.args[1]
    (struct_name, type_params, super) = _parse_head(expr.args[2])
    line_tuples = _parse_line.(expr.args[3].args)

    lines = first.(line_tuples)
    type_params = (type_params..., filter(x -> x!==nothing, last.(line_tuples))...)
    struct_type = Expr(:curly, struct_name, type_params...)

    head = Expr(:(<:), struct_type, super)
    body = Expr(:block, lines...)

    return Expr(:struct, maybe_mutable, head, body)
end


# Parse the top line of the struct definition
_parse_head(head::Symbol) = (_parse_struct_def(head)..., :(Any))
function _parse_head(head::Expr)
    if head.head === :curly
        super = :(Any)
        struct_name, type_params = _parse_struct_def(head)
    elseif head.head === :(<:)
        super = head.args[2]
        struct_name, type_params = _parse_head(head.args[1])
    end
    
    return (struct_name, type_params, super)
end


# Parse the struct name and parameters
_parse_struct_def(struct_def::Symbol) = (struct_def, [])
_parse_struct_def(struct_def::Expr) = (struct_def.args[1], struct_def.args[2:end])


# Parse a line of the body of the struct def. Returns the line and the type parameter to be
# included in the struct header
_parse_line(line::LineNumberNode) = (line, nothing)
_parse_line(line::Expr) = (line, nothing)
function _parse_line(line::Symbol)
    T = Symbol("__T_" * string(line))
    return (:($line::$T), T)
end


end
