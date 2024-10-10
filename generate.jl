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

function examplesmarkdown(examples=WordCloud.EXAMPLES; doeval=doeval, exception=exception)
    mds= [
    "# WordCloud-Gallery\n"
    "This is a gallery of [WordCloud.jl](https://github.com/guo-yong-zhi/WordCloud), which is automatically generated from `WordCloud.EXAMPLES` (WordCloud v$(pkgversion(WordCloud))).  "
    "Run `evalfile(\"generate.jl\", [\"doeval=true\", \"exception=true\"])` in julia REPL to create this file.  \n"
    ["- [$e](#$(lowercase(replace(e, " "=>"-"))))\n" for e in examples]...
    ]
    doeval = doeval isa Bool ? doeval : Set(string.(doeval))
    for e in examples
        println("#"^10, e, "#"^10)
        try
            push!(mds, "# $e\n")
            de = doeval isa Bool ? doeval : e in doeval
            markdownsource(pkgdir(WordCloud)*"/examples/$e.jl", mds, doeval=de)
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