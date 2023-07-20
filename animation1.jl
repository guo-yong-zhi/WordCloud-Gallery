#md# This animation shows how the WordCloud.jl works.
using WordCloud
docs = (readdir(joinpath(dirname(Sys.BINDIR), "share/doc/julia/html/en", dir), join=true) for dir in ["manual", "base", "stdlib"])
docs = docs |> Iterators.flatten
words, weights = processtext(maxnum=200, maxweight=1) do
    counter = Dict{String,Int}()
    for doc in docs
        content = html2text(open(doc))
        countwords(content, counter=counter)
    end
    counter
end
colors=collect(WordCloud.colorschemes[:seaborn_deep6].colors)
wc = wordcloud(
    words, weights, 
    masksize = (300, 200),
    outline = 3, linecolor=colors[3],
    angles = 0:90,
    mask=squircle,rt=0.92,backgroundcolor="white",fonts="dyuthi",
    spacing=1, density=0.5, colors=[colors[3:end]; colors[1:2]],
    state = initialize!)
setangles!(wc, "julia", 0)
initialize!(wc, "julia")
#md# ### uniform style
gifdirectory = "animation1/uniform"
setpositions!(wc, :, (-1000,-1000))
@record gifdirectory overwrite=true filter=i->i%(2^(i÷100))==0 layout!(wc, style=:uniform)
@record "animation1/uniform_fit" overwrite=true generate!(wc, 100, optimiser=WordCloud.Momentum())
#md# ![](animation1/uniform/animation.gif)  
#md# ### gathering style
gifdirectory = "animation1/gathering"
setpositions!(wc, :, (-1000,-1000))
@record gifdirectory overwrite=true filter=i->i%(2^(i÷100))==0 layout!(wc, style=:gathering)
@record "animation1/gathering_fit" overwrite=true generate!(wc, 100, optimiser=WordCloud.Momentum())
#md# ![](animation1/gathering/animation.gif)  
#md# 
println("results are saved in animation1")
wc
#eval# runexample(:animation1)