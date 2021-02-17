# WordCloud-Gallery
This is a gallery of [WordCloud](https://github.com/guo-yong-zhi/WordCloud), which is automatically generated from `WordCloud.examples`.  Run `evalfile("generate.jl", ["doeval=true", "exception=true"])` to create this file.  
* [alice](#alice)
* [animation](#animation)
* [benchmark](#benchmark)
* [compare](#compare)
* [fromweb](#fromweb)
* [juliadoc](#juliadoc)
* [lettermask](#lettermask)
* [pattern](#pattern)
* [qianziwen](#qianziwen)
* [random](#random)
* [specifiedstyle](#specifiedstyle)
* [中文](#中文)
# alice
```julia
using WordCloud
wc = wordcloud(
    processtext(open(pkgdir(WordCloud)*"/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"]), 
    mask = loadmask(pkgdir(WordCloud)*"/res/alice_mask.png", color="#faeef8"),
    colors = :seaborn_dark,
    angles = (0, 90),
    fillingrate = 0.7) |> generate!
println("results are saved to alice.png")
paint(wc, "alice.png", background=outline(wc.mask, color="purple", linewidth=1))
wc
```  
![alice](alice.png)  
# animation
```julia
using CSV
using DataFrames
using WordCloud

df = CSV.File(pkgdir(WordCloud)*"/res/guxiang_frequency.txt", header=false)|> DataFrame;
words = df[!, "Column2"]
weights = df[!, "Column3"]

wc = wordcloud(words, weights, fillingrate=0.8)
gifdirectory = "guxiang_animation"
generate_animation!(wc, 100, outputdir=gifdirectory)
println("results are saved in guxiang_animation")
wc
```  
![](guxiang_animation/result.gif)  
# benchmark
```julia
using WordCloud
using Random

println("This test will take several minutes")

words = [Random.randstring(rand(1:8)) for i in 1:200]
weights = randexp(length(words)) .* 2000 .+ rand(20:100, length(words));
wc1 = wordcloud(words, weights, mask=shape(ellipse, 500, 500, color=0.15), angles=(0,90,45), fillingrate=0.7)

words = [Random.randstring(rand(1:8)) for i in 1:500]
weights = randexp(length(words)) .* 2000 .+ rand(20:100, length(words));
wc2 = wordcloud(words, weights, mask=shape(ellipse, 500, 500, color=0.15), angles=(0,90,45))

words = [Random.randstring(rand(1:8)) for i in 1:5000]
weights = randexp(length(words)) .* 2000 .+ rand(20:100, length(words));
wc3 = wordcloud(words, weights, mask=shape(box, 2000, 2000, 100, color=0.15), angles=(0,90,45))

wcs = [wc1, wc1, wc2, wc3] #repeat wc1 to trigger compiling
ts = [WordCloud.trainepoch_E!,WordCloud.trainepoch_EM!,WordCloud.trainepoch_EM2!,WordCloud.trainepoch_EM3!,
        WordCloud.trainepoch_P!,WordCloud.trainepoch_P2!,WordCloud.trainepoch_Px!]
for (i,wc) in enumerate(wcs)
    println("\n\n", "*"^10, "wordcloud - $(length(wc.words)) words on mask$(size(wc.mask))", "*"^10)
    for (j,t) in enumerate(ts)
        println("\n", i-1, "==== ", j, "/", length(ts), " ", nameof(t))
        placement!(wc)
        @time generate!(wc, trainer=t, retry=1)
    end
end
```  
# compare
### First generate the wordcloud on the left  
```julia
using WordCloud

stwords = ["us", "will"];
println("==Obama's==")
cs = WordCloud.randomscheme()
as = WordCloud.randomangles()
fr = 0.65 #not too high
wca = wordcloud(
    processtext(open(pkgdir(WordCloud)*"/res/Barack Obama's First Inaugural Address.txt"), stopwords=WordCloud.stopwords_en ∪ stwords), 
    colors = cs,
    angles = as,
    fillingrate = fr) |> generate!
```  
### Then generate the wordcloud on the right      
```julia
println("==Trump's==")
wcb = wordcloud(
    processtext(open(pkgdir(WordCloud)*"/res/Donald Trump's Inaugural Address.txt"), stopwords=WordCloud.stopwords_en ∪ stwords),
    mask = getmask(wca),
    colors = cs,
    angles = as,
    fillingrate = fr,
    run = x->nothing, #turn off the useless initimage! and placement! in advance
)

samewords = getwords(wca) ∩ getwords(wcb)
println(length(samewords), " same words")

for w in samewords
    setcolors!(wcb, w, getcolors(wca, w))
    setangles!(wcb, w, getangles(wca, w))
end
#Follow these steps to generate result: initimage! -> placement! -> generate!
initimages!(wcb)

println("=ignore defferent words=")
ignore(wcb, getwords(wcb) .∉ Ref(samewords)) do
    @assert Set(wcb.words) == Set(samewords)
    centers = getpositions(wca, samewords, type=getcenter)
    setpositions!(wcb, samewords, centers, type=setcenter!) #manually initialize the position,
    setstate!(wcb, :placement!) #and set the state flag
    generate!(wcb, 1000, patient=-1, retry=1) #patient=-1 means no teleport; retry=1 means no rescale
end

println("=pin same words=")
pin(wcb, samewords) do
    placement!(wcb)
    generate!(wcb, 1000, retry=1) #allow teleport but don‘t allow rescale
end

if getstate(wcb) != :generate!
    println("=overall tuning=")
    generate!(wcb, 1000, patient=-1, retry=2) #allow rescale but don‘t allow teleport
end

ma = paint(wca)
mb = paint(wcb)
h,w = size(ma)
space = fill(mb[1], (h, w÷20))
try mkdir("address_compare") catch end
println("results are saved in address_compare")
WordCloud.save("address_compare/compare.png", [ma space mb])
gif = WordCloud.GIF("address_compare")
record(wca, "Obama", gif)
record(wcb, "Trump", gif)
WordCloud.Render.generate(gif, framerate=1)
wca, wcb
```  
![](address_compare/compare.png)  
![](address_compare/result.gif)  
# fromweb
# juliadoc
```julia
using WordCloud
function drawjuliacircle(sz)
    juliacirclessvg = WordCloud.Render.Drawing(sz, sz, :svg)
    WordCloud.Render.origin()
    WordCloud.Render.background(0,0,0,0)
    WordCloud.Render.juliacircles(sz÷4)
    WordCloud.Render.finish()
    juliacirclessvg
end

docs = (readdir(joinpath(dirname(Sys.BINDIR), "share/doc/julia/html/en", dir), join=true) for dir in ["manual", "base", "stdlib"])
docs = docs |> Iterators.flatten

words, weights = processtext(maxnum=300, maxweight=1) do
    counter = Dict{String,Int}()
    for doc in docs
        content = html2text(open(doc))
        countwords(content, counter=counter)
    end
    counter
end

wc = wordcloud(
    [words..., "∴"], #add a placeholder for julia-logo
    [weights..., weights[1]], 
    fillingrate=0.8,
    mask = shape(box, 900, 300, 0, color=0.95, backgroundcolor=(0,0,0,0)),
    colors = ((0.796,0.235,0.20), (0.584,0.345,0.698), (0.22,0.596,0.149)),
    angles = (0, -45, 45),
    # font = "Georgia",
    transparentcolor=(0,0,0,0),
)
setangles!(wc, "julia", 0)
setcolors!(wc, "julia", (0.796,0.235,0.20))
# setfonts!(wc, "julia", "forte")
initimage!(wc, "julia")
juliacircles = drawjuliacircle(getfontsizes(wc, "∴")|>round)
setsvgimages!(wc, "∴", juliacircles) #replace image
sz1 = size(getimages(wc, "∴"))
sz2 = size(getimages(wc, "julia"))
y1, x1 = (size(wc.mask) .- (sz1[1], sz1[2]+sz2[2])) .÷ 2
y2 = (size(wc.mask, 1) - sz2[1]) ÷ 2
setpositions!(wc, "∴", (x1, y1))
setpositions!(wc, "julia", (x1+sz1[2], y2))

pin(wc, ["julia", "∴"]) do
    placement!(wc)
    generate!(wc, 2000)
end
println("results are saved to juliadoc.svg")
# paint(wc, "juliadoc.png")
paint(wc, "juliadoc.svg")
wc
```  
![](juliadoc.svg)  
# lettermask
```julia
using WordCloud
mask = rendertext("World", 1000, border=10, color=0.9, backgroundcolor=0.98, type=:svg, font="Georgia-Bold")
words = repeat(["we", "are", "the", "world"], 150)
weights = repeat([1], length(words))
wc = wordcloud(
        words, weights, 
        mask = mask,
        angles = 0,
        colors = ("#006BB0", "#EFA90D", "#1D1815", "#059341", "#DC2F1F"),
        fillingrate=0.7,
        ) |> generate!
println("results are saved to lettermask.svg")
paint(wc, "lettermask.svg" , background=false)
wc
```  
![](lettermask.svg)  
# pattern
```julia
using WordCloud

sc = WordCloud.randomscheme()
l = 200
#`words` & `weights` just as placeholders
# style arguments like `colors`, `angles` and `fillingrate` have no effect
wc = wordcloud(
    repeat(["placeholder"], l), repeat([1], l), 
    mask = shape(box, 400, 300, color=WordCloud.chooseabgcolor(sc)),
    transparentcolor = (0,0,0,0),
    run=x->x)

# manually initialize images for the placeholders, instead of calling `initimages!`
## svg version
#shapes = [shape(ellipse, repeat([floor(20expm1(rand())+5)],2)..., color=rand(sc)) for i in 1:l]
#setsvgimages!(wc, :, shapes)
## bitmap version
shapes = WordCloud.svg2bitmap.([shape(ellipse, repeat([floor(15expm1(rand())+5)],2)..., color=rand(sc)) for i in 1:l])
setimages!(wc, :, shapes)

setstate!(wc, :initimages!) #set the state flag after manual initialization
# generate_animation!(wc, retry=1, outputdir="pattern_animation")
generate!(wc, retry=1) #turn off rescale attempts. manually set images can't be rescaled
println("results are saved to pattern.png")
paint(wc, "pattern.png")
wc
```  
![](pattern.png)  
# qianziwen
```julia
using WordCloud
words = "天地玄黄宇宙洪荒日月盈昃辰宿列张寒来暑往秋收冬藏闰余成岁律吕调阳云腾致雨露结为霜金生丽水玉出昆冈剑号巨阙珠称夜光果珍李柰菜重芥姜海咸河淡鳞潜羽翔龙师火帝鸟官人皇始制文字乃服衣裳推位让国有虞陶唐吊民伐罪周发殷汤坐朝问道垂拱平章"
words = [string(c) for c in words]
weights = rand(length(words)) .^ 2 .* 100 .+ 30
wc = wordcloud(words, weights)
generate!(wc)```  
# random
```julia
using WordCloud
using Random

words = [Random.randstring(rand(1:8)) for i in 1:500]
weights = randexp(length(words)) .* 2000 .+ rand(20:100, length(words));
wc = wordcloud(words, weights, mask=shape(ellipse, 500, 500, color=0.15), angles=(0,90,45)) |> generate!```  
# specifiedstyle
```julia
using WordCloud
wc = wordcloud(
    processtext(open(pkgdir(WordCloud)*"/res/alice.txt"), stopwords=WordCloud.stopwords_en ∪ ["said"], maxweight=1, maxnum=300), 
    # mask = padding(WordCloud.svg2bitmap(shape(ellipse, 600, 500, color=(0.98, 0.97, 0.99), backgroundcolor=0.97)), 0.1),
    mask = shape(ellipse, 600, 500, color=(0.98, 0.97, 0.99), backgroundcolor=0.97, backgroundsize=(700, 550)),
    colors = :seaborn_dark,
    angles = -90:90,
    run=x->x, #turn off the useless initimage! and placement! in advance
)

setwords!(wc, "Alice", "Alice in Wonderland") # replace the word 'Alice' with 'Alice in Wonderland'
setangles!(wc, "Alice in Wonderland", 0) # make it horizontal
setcolors!(wc, "Alice in Wonderland", "purple");
setfontsizes!(wc, "Alice in Wonderland", 2.1size(wc.mask, 2)/length("Alice in Wonderland")) # set a big font size
initimage!(wc, "Alice in Wonderland") # init it after adjust it's style
setpositions!(wc, "Alice in Wonderland", reverse(size(wc.mask)) .÷ 2, type=setcenter!) # center it

pin(wc, "Alice in Wonderland") do
    initimages!(wc) #init inside `pin` to reset the size of other words
    generate!(wc)
end

println("results are saved to specifiedstyle.svg")
paint(wc, "specifiedstyle.svg")
wc
```  
![](specifiedstyle.svg)  
# 中文
