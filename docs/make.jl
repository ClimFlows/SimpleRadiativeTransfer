using SimpleRadiativeTransfer
using Documenter

DocMeta.setdocmeta!(SimpleRadiativeTransfer, :DocTestSetup, :(using SimpleRadiativeTransfer); recursive=true)

makedocs(;
    modules=[SimpleRadiativeTransfer],
    authors="Thomas Dubos <thomas.dubos@polytechnique.edu> and contributors",
    sitename="SimpleRadiativeTransfer.jl",
    format=Documenter.HTML(;
        canonical="https://dubosipsl.github.io/SimpleRadiativeTransfer.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/dubosipsl/SimpleRadiativeTransfer.jl",
    devbranch="main",
)
