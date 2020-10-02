# Walkthrough
The `@concrete` macro can be tacked onto any `struct` definition that isn't already concretely-typed. That's kinda all there is to it, but let's walk through some examples anyway to get a feel for it.

In this example, no type parameters are given, so they will be filled in automatically:

```julia
@concrete struct Whatever
    a
    b
end
```
```julia-repl
julia> complex_whatever = Whatever(1+im, "It's pretty complex")
Whatever{Complex{Int64},String}(1 + 1im, "It's pretty complex")
```

But maybe we don't want to show the type parameters, since we never cared much about them in the first place. If we want our `struct` to print a little more succintly, we can add the `terse` keyword. Now it will print as if we never added the `@concrete` macro.

```julia
@concrete terse struct PrettierWhatever
    a
    b
end
```
```julia-repl
julia> pretty_whatever = PrettierWhatever(1+im, "It's still pretty complex")
PrettierWhatever(1 + 1im, "It's still pretty complex")
```
The full type information is still available for inspection with the `typeof` function, though.
```julia-repl
julia> typeof(pretty_whatever)
PrettierWhatever{Complex{Int64},String}
```

More complicated type parameterizations are possible as well. Take this example of an array with two metadata fields attached. The type parameters for the `array` field are provided but the `name` field's type is left open. The `@concrete` macro will respect the given type parameters and concretely parameterize the `name` field.

```julia
@concrete struct MetaArray{T,N,A<:AbstractArray{T,N}} <: AbstractArray{T,N}
    array::A
    name
end

Base.size(x::MetaArray) = size(x.array)

Base.getindex(x::MetaArray, i...) = getindex(x.array[i...])
```
```julia-repl
julia> abed = MetaArray([8,10,2,5], "Abed")
4-element MetaArray{Int64,1,Array{Int64,1},String}:
  8
 10
  2
  5
```

We can also have type parameters that don't correspond to any field. In this example, the `BananaStand` type is parameterized by the boolean value `has_money`. 

```julia
@concrete terse mutable struct BananaStand{has_money}
    employees
    manager
end
```

In this case, the constructor must be given with the `has_money` parameter, just like it would need to be if we weren't using the `@concrete` macro. Since the `terse` keyword was give, the type will print exactly as it's specified: with the `has_money` parameterization but no field parameterizations.

```julia-repl
julia> the_banana_stand = BananaStand{true}(["Maeby", "Annyong"], "George Michael")
BananaStand{true}(["Maeby", "Annyong"], "George Michael")

julia> typeof(the_banana_stand)
BananaStand{true,Array{String,1},String}
```

