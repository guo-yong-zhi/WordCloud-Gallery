function newline!(results)
    if !isempty(results) && !endswith(results[end], "\n")
        push!(results, "\n")
    end
end
function markdownsource(f, results=[]; doeval=true, exception=exception)
    c = []
    function code(c)
        if isempty(c) return end
        newline!(results)
        push!(results, "```julia\n")
        append!(results, c)
        empty!(c)
        newline!(results)
        push!(results, "```  \n")
    end
    for l in eachline(f, keep=true)
        if startswith(l, "#md#")
            code(c)
            push!(results, l[6:end])
        elseif startswith(l, "#eval#")
            if doeval
                try
                    eval(Meta.parse(l[8:end]))
                catch ex
                    if exception
                        throw(ex)
                    else
                        @warn ex
                    end
                end
            end
        else
            push!(c, l)
        end
    end
    code(c)
    results
end

using WordCloud
eval.(Meta.parse.(ARGS))
doeval = (@isdefined doeval) ? doeval : true
exception = (@isdefined exception) ? exception : true
using Pkg
using UUIDs
ctx = Pkg.Operations.Context()
v = ctx.env.manifest[UUID("6385f0a0-cb03-45b6-9089-4e0acc74b26b")].version

function examplesmarkdown(examples=WordCloud.examples; doeval=doeval, exception=exception)
    mds= [
    "# WordCloud-Gallery\n"
    "This is a gallery of [WordCloud](https://github.com/guo-yong-zhi/WordCloud), which is automatically generated from `WordCloud.examples` (WordCloud v$v).  "
    "Run `evalfile(\"generate.jl\", [\"doeval=true\", \"exception=true\"])` in julia REPL to create this file.  \n"
    ["- [$e](#$(lowercase(replace(e, " "=>"-"))))\n" for e in examples]...
    ]
    for e in examples
        println("#"^10, e, "#"^10)
        try
            push!(mds, "# $e\n")
            markdownsource(pkgdir(WordCloud)*"/examples/$e.jl", mds, doeval=doeval)
            newline!(mds)
        catch ex
            if exception
                throw(ex)
            else
                @warn ex
            end
        end
    end
    mds
end

function main()
    write("README.md", examplesmarkdown()...);
end
main()