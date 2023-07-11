"""
    ConcreteStructs

ConcreteStructs exports the macro `@concrete`, which can be used to concretely parameterize
structs.
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
    expr, _, _ = _concretize(expr)
    return esc(expr)
end

macro concrete(terse, expr)
    terse isa Symbol && terse == :terse || error("Invalid usage of @concrete")

    expr, struct_name, type_params = _concretize(expr)
    struct_name = string(struct_name)
    num_params = length(type_params)
    
    terse_string = if num_params == 0
        struct_name
    else
        :($(struct_name) * "{" * join(T.parameters[1:$num_params], ",") * "}")
    end

    return quote
        $(Base).@__doc__ $expr
        function Base.show(io::IO, T::Type{<:$(Symbol(struct_name))})
            if T isa UnionAll
                print(io, $struct_name)
            else
                print(io, $(struct_name) * "{" * join(T.parameters[1:$num_params], ",") * "}")
            end
        end
        function Base.show(io::IO, ::MIME"text/plain", T::Type{<:$(Symbol(struct_name))})
            if T isa UnionAll
                return print(io, $struct_name)
            else
                return print(io, $(struct_name) * "{" * join(T.parameters, ",") * "}")
            end
        end
    end |> esc
end


# Parse whole struct definition for the @concrete macro
function _concretize(expr)
    original_expr, expr = _find_struct_def(expr)

    is_mutable = expr.args[1]
    struct_name, type_params, super = _parse_head(expr.args[2])
    line_tuples = _parse_line.(expr.args[3].args)
    lines = first.(line_tuples)
    type_params_full = (type_params..., filter(x -> x!==nothing, last.(line_tuples))...)

    struct_type = if length(type_params_full) == 0
        struct_name
    else
        Expr(:curly, struct_name, type_params_full...)
    end

    head = Expr(:(<:), struct_type, super)
    constructor_expr = _make_constructor(struct_name, type_params, type_params_full, lines)
    body = Expr(:block, lines..., constructor_expr)
    struct_expr = Expr(:struct, is_mutable, head, body)
    
    struct_expr = _apply_original_expr(original_expr, struct_expr)

    return struct_expr, struct_name, type_params
end


# Make the inner constructor function
function _make_constructor(struct_name, type_params, type_params_full, lines)
    lines = map(line->line isa Expr && line.head==:(=) ? line.args[1] : line, lines)
    field_lines = filter(line -> ((line isa Expr) && (line.head === :(::))), lines)
    args = map(x->x.args, field_lines)
    vars = first.(args)
    var_types = last.(args)
    constructor_params = _get_constructor_params(type_params, var_types)
    new_params = _strip_super(type_params_full)

    if length(type_params) == length(type_params_full) && all(type_params .== type_params_full)
        return Expr(:block)
    elseif length(constructor_params)==0
        return :(
            function $struct_name($(field_lines...)) where {$(type_params_full...)}
                return new{$(new_params...)}($(vars...))
            end
        )
    else
        return :(
            function $struct_name{$(constructor_params...)}($(field_lines...)) where {$(type_params_full...)}
                return new{$(new_params...)}($(vars...))
            end
        )
    end
end


# Get the parameters that are unmatched to variables and need to be annoted in the constructor
function _get_constructor_params(type_params, var_types)
    subparams = _get_subparams(type_params)
    type_params = _strip_super(type_params)
    var_types = [subparams; _strip_super(var_types)]
    return setdiff(type_params, var_types)
end


# Strip supertype annotations
_strip_super(x) = x
_strip_super(x::Union{Tuple, AbstractVector}) = vcat(_strip_super.(x)...)
_strip_super(x::Expr) = x.head == :(<:) ? x.args[1] : x


# Get the subparameters of supertypes of subtype parameters (sorry)
_get_subparams(x) = []
_get_subparams(x::Union{Tuple, AbstractVector}) = vcat(_get_subparams.(x)...)
function _get_subparams(x::Expr)
    if x.head === :curly
        return x.args[2:end]
    elseif x.head === :(<:)
        return _get_subparams(x.args[2:end])
    end
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
_parse_line(line) = (line, nothing)
function _parse_line(line::Expr)
    assignment = line.head === :(=)
    annotation = nothing
    if assignment
        val = line.args[2]
        line, annotation = _parse_line(line.args[1])
    end

    out = if line isa Expr && line.head === :(<:)
        field = line.args[1]
        T = line.args[2]
        sym = Symbol(:__T_, field)
        (:($field::$sym), :($sym<:$T))
    else
        (line, annotation)
    end

    return if assignment
        (:($(out[1])=$val), out[2])
    else
        out
    end

    
    # if (T isa Symbol && isdefined(Base.Main, T) && !isconcretetype(Base.eval(Base.Main, T))) || T isa Expr
    #     sym = Symbol("__T_" * string(field))
    #     return (:($field::$sym), :($sym<:$T))
    # else
    #     return (line, nothing)
    # end
end
function _parse_line(line::Symbol)
    T = Symbol("__T_" * string(line))
    return (:($line::$T), T)
end

# find the struct def in case its encapsuled in other macros
# returns full_original_expression, struct_definition_expr
function _find_struct_def(expr; tl_expr = expr)
    if expr.head == :struct
        return tl_expr, expr
    elseif expr.head == :macrocall
        return _find_struct_def(expr.args[3]; tl_expr = tl_expr)
    end
    return nerror("Invalid usage of @concrete.")
end

# finds where the struct is defined in original_expr and plugs in struct_expr
function _apply_original_expr(original_expr, struct_expr)
    if original_expr.head == :struct
        original_expr.args = struct_expr.args
    elseif original_expr.head == :macrocall
        original_expr.args[3] = _apply_original_expr(original_expr.args[3], struct_expr)
    else
        error("Unsupported expression.")
    end
    return original_expr
end

end
