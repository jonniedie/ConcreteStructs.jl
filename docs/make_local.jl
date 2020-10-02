using Documenter
using ConcreteStructs

makedocs(
    modules = [ConcreteStructs],
    sitename = "ConcreteStructs.jl",
    pages =[
        "Home" => "index.md",
        "Walkthrough" => "walkthrough.md",
        "API" => "api.md",
    ],
    format = Documenter.HTML(
        canonical = "https://jonniedie.github.io/ConcreteStructs.jl/stable",
        prettyurls=false,
    ),
    repo="https://github.com/jonniedie/ConcreteStructs.jl/blob/{commit}{path}#L{line}",
    authors = "Jonnie Diegelman",
    assets = String[],
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/jonniedie/ConcreteStructs.jl.git"
)
