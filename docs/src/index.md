# ConcreteStructs.jl

ConcreteStructs exports the macro `@concrete` that will add type parameters to your struct for any field where type parameters aren’t given.

Simply add the `@concrete` macro before any valid `struct` definition and it should automagically make all of your non-type-annotated fields type-annotated. If you don't like the verbose type printing 

