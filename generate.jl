function markdownsource(f, results=[]; doeval=true)
    c = []
    function code(c)
        if isempty(c) return end
        push!(results, "\n```julia\n")
        append!(results, c)
        empty!(c)
        push!(results, "\n```  \n")
    end
    for l in eachline(f, keep=true)
        if startswith(l, "#md#")
            code(c)
            push!(results, lstrip(l[5:end]))
        elseif startswith(l, "#eval#")
            if doeval
                eval(Meta.parse(lstrip(l[7:end])))
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
exception = (@isdefined exception ) ? exception : true

function examplesmarkdown(examples=WordCloud.examples)
    mds= [
    "# WordCloud-Gallery\n"
    "This is a gallery of [WordCloud](https://github.com/guo-yong-zhi/WordCloud), which is automatically generated from `WordCloud.examples`.  "
    "Run `evalfile(\"generate.jl\", [\"doeval=true\", \"exception=true\"])` to create this file.  \n"
    ["* [$e](#$e)\n" for e in examples]...
    ]
    for e in examples
        println("#"^10, e, "#"^10)
        try
            e = replace(e, " "=>"-")
            push!(mds, "# $e\n")
            markdownsource(pkgdir(WordCloud)*"/examples/$e.jl", mds, doeval=doeval)
            if !isempty(mds) && !endswith(mds[end], "\n")
                push!(mds, "\n")
            end
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
    write("README.md", examplesmarkdown()...)
end
main()