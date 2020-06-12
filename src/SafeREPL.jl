module SafeREPL

Base.Experimental.@optlevel 0

export swapliterals!


using SwapLiterals: SwapLiterals, makedict, floats_use_rationalize!,
                    literalswapper, default_literalswapper, defaultswaps

using REPL


function __init__()
    # condensed equivalent version of `swapliterals!()`, for faster loading
    push!(get_transforms(), default_literalswapper)
end

const LAST_SWAPPER = Ref{Function}(default_literalswapper)


function get_transforms()
    if isdefined(Base, :active_repl_backend) &&
        isdefined(Base.active_repl_backend, :ast_transforms)
        Base.active_repl_backend.ast_transforms::Vector{Any}
    else
        REPL.repl_ast_transforms::Vector{Any}
    end
end

"""
    SafeREPL.swapliterals!(Float64, Int, Int128, BigInt=nothing, Float64=nothing)

Specify transformations for literals:
argument `Float64` corresponds to literals of type `Float64`, etcetera.

A transformation can be
* a `Symbol`, to refer to a function, e.g. `:big`;
* `nothing` to not transform literals of this type;
* a `String` specifying the name of a string macro, e.g. `"@big_str"`,
  which will be applied to the input. Available only for
  `Int128` and `BigInt`, and experimentally for `Float64`.
"""
function swapliterals!(Int
                       Int128,
                       BigInt=nothing)
                       Float64=nothing)
    @nospecialize
    swapliterals!(; Int, Int128, BigInt, Float64)
end

function swapliterals!(@nospecialize(swaps::AbstractDict))
    swapliterals!(false) # remove previous settings

    LAST_SWAPPER[] = swaps === defaultswaps ? default_literalswapper :
                                              literalswapper(swaps)

    push!(get_transforms(), LAST_SWAPPER[])
    nothing
end

# called only when !isempty(swaps)
swapliterals!(swaps::Pair...) = swapliterals!(makedict(swaps))

# non-public API when !isempty(kwswaps)
function swapliterals!(; kwswaps...)
    swapliterals!(
        isempty(kwswaps) ?
            defaultswaps :
            makedict(Any[getfield(Base, first(sw)) => last(sw) for sw in kwswaps]))
end

function swapliterals!(activate::Bool)
    transforms = get_transforms()
    # first always de-activate
    filter!(f -> parentmodule(f) != SwapLiterals, transforms)
    if activate
        push!(transforms, LAST_SWAPPER[])
    end
    nothing
end

isactive() = any(==(SwapLiterals) ∘ parentmodule, get_transforms())


end # module
