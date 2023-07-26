### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ daf38998-c448-498a-82e2-b48a6a2b9c27
# ╠═╡ show_logs = false
begin
    using Fontconfig_jll
    using Downloads: download
    function install_juliamono(path)
        if !(isfile("$path/juliamono.zip"))
            download("https://github.com/cormullion/juliamono/releases/download/v0.050/JuliaMono-ttf.zip", "$path/juliamono.zip")
            run(`bash -c "cd $path; unzip juliamono"`)
        end
    end
    function install_unifont(path)
        download("https://unifoundry.com/pub/unifont/unifont-15.0.06/font-builds/unifont-15.0.06.ttf", "$path/unifont.ttf")
    end
    function install_wqy(path)
        if !(isfile("$path/wqy-microhei.tar.gz"))
            download("https://jaist.dl.sourceforge.net/project/wqy/wqy-microhei/0.2.0-beta/wqy-microhei-0.2.0-beta.tar.gz", "$path/wqy-microhei.tar.gz")
            run(`bash -c "cd $path; tar -xf wqy-microhei.tar.gz"`)
        end
        if !(isfile("$path/wqy-bitmapsong.tar.gz"))
            download("https://jaist.dl.sourceforge.net/project/wqy/wqy-bitmapfont/1.0.0-RC1/wqy-bitmapsong-pcf-1.0.0-RC1.tar.gz", "$path/wqy-bitmapsong.tar.gz")
            run(`bash -c "cd $path; tar -xf wqy-bitmapsong.tar.gz"`)
        end
    end
    if homedir() == "/home/jrun"
		font_folder = "/home/jrun/.local/share/fonts"
		run(`bash -c "mkdir -p $font_folder"`)
		# run(`bash -c "ls $font_folder"`)
		install_juliamono(font_folder)
		install_unifont(font_folder)
		install_wqy(font_folder)
		# run(`bash -c "cd $(font_folder); ls"`)
		Fontconfig_jll.fc_cache() do exe
			run(`$exe`)
		end
    end
    
    using PlutoUI
    using WordCloud
    using HTTP
    using ImageIO
    using PythonCall
    using CondaPkg
    CondaPkg.add("jieba")
    nothing
end

# ╔═╡ 10b8d675-ee35-46dd-aee7-6792749d16f2
md"# How to Generate a Word Cloud"

# ╔═╡ e4ab8ddd-0486-420d-a90d-e57714ef02de
md"""
`Word cloud`, also known as `tag cloud`, is a popular visual representation of textual data. It conveys word importance through font size, position, or color. Word clouds are ubiquitous across the internet, like those examples below.
"""

# ╔═╡ 4b5544d3-230f-499f-94b1-dd05f595ef88
Resource("https://github.com/guo-yong-zhi/WordCloud-Gallery/blob/instruction/wordclouds.png?raw=true")

# ╔═╡ ffa6f9f4-0a00-409c-a4c3-b00a0060877f
md"""
How to generate a word cloud with algorithm? A direct answer to this question would be that we initially place the words and then carefully adjust their positions until they do not overlap.
"""

# ╔═╡ 04a2b044-3e90-4c22-a2af-143f5476b6c8
md"""
The algorithm for placing words is relatively simple since each word is positioned only once, making efficiency less critical. Different placing strategies will result in different word cloud styles. For instance, the two approaches below lead to a uniform style and a gathering style, respectively.
"""

# ╔═╡ c51883b6-5ef6-4a78-bdc2-b39e49403ecf
md"**Placing — Uniform style**"

# ╔═╡ a186a333-3f34-4973-a1b0-d7cdc6394c3c
Resource("https://github.com/guo-yong-zhi/WordCloud-Gallery/blob/instruction/animation1/uniform/animation.gif?raw=true")

# ╔═╡ e5d15923-9a17-493d-b2af-244509e1e3ba
md"**Placing — Gathering style**"

# ╔═╡ b5c9984a-3829-4fd8-9722-99f45806745b
Resource("https://github.com/guo-yong-zhi/WordCloud-Gallery/blob/instruction/animation1/gathering/animation.gif?raw=true")

# ╔═╡ 3826a575-abef-4633-93ee-78a299da9998
md"""
Developing an effective algorithm for adjusting positions presents a considerable challenge. The efficiency of this step is rather critical as it involves repeated movement of words. The subsequent adjusting processes of the above examples are shown in the following pictures.
"""

# ╔═╡ 0e5f246d-aae1-4c4d-b6cd-92b2d2f617f9
md"**Adjustment — Uniform style**"

# ╔═╡ f2dda08e-ad06-49a6-b867-df2a16393a36
Resource("https://github.com/guo-yong-zhi/WordCloud-Gallery/blob/instruction/animation1/uniform_fit/animation.gif?raw=true")

# ╔═╡ 638fa2aa-24c4-4867-ad2b-aa9e800fe324
md"**Adjustment — Gthering style**"

# ╔═╡ 024a576b-a38d-4eac-bf90-537c46a0be90
Resource("https://github.com/guo-yong-zhi/WordCloud-Gallery/blob/instruction/animation1/gathering_fit/animation.gif?raw=true")

# ╔═╡ 13d75a82-7983-44c0-b367-563ef338a066
md"""
The following discussion focuses on the more difficult part — adjustment algorithm, which consists of three main steps.
"""

# ╔═╡ 2d30826d-5730-4f58-9c01-09f7c4aeb54d
md"""
1. **Ternary Raster Pyramid Construction**: Initially, a binary raster mask is created for each word, and based on this, a ternary raster pyramid is constructed. This pyramid comprises downsampled layers of the original mask. Each subsequent layer is downsampled at a 2:1 scale. Consequently, the pyramid can be viewed as a collection of hierarchical bounding boxes. Each pixel in every layer (tree node) can take one of three values: `FULL`, `EMPTY`, or `MIX`. $(Resource("https://github.com/guo-yong-zhi/Stuffing.jl/blob/main/res/pyramid1.png?raw=true")) $(Resource("https://github.com/guo-yong-zhi/Stuffing.jl/blob/main/res/pyramid2.png?raw=true"))
"""

# ╔═╡ a3b208a3-20c0-439e-96fd-10b0e5cc188a
md"""
2. **Top-Down Collision Detection**: The algorithm employs a top-down approach to identify collisions between two pyramids or trees. At level 𝑙 and coordinates (𝑎,𝑏), if a node in one tree is `FULL` and the corresponding node in the other tree is not `EMPTY`, a collision occurs at (𝑙,𝑎,𝑏). However, pairwise collision detection between multiple objects would be time-consuming. To address this, the algorithm first locates the objects within hierarchical sub-regions. It then detects collisions between objects within each sub-region and between objects in sub-regions and their ancestral regions. $(Resource("https://github.com/guo-yong-zhi/Stuffing.jl/blob/main/res/collision.png?raw=true"))
"""

# ╔═╡ b7c1e2a5-d5ae-4e97-a1b0-a9f2d99a1100
md"""
3. **Object Movement and Reconstruction**: In the final step, each object in a collision pair is moved based on the local gradient near the collision point (𝑙,𝑎,𝑏). The movement aims to separate the objects and create more space between them. Specifically, the objects are shifted away from the `EMPTY` regions. After moving the objects, the algorithm rebuilds the pyramids to prepare for the next round of collision detection. $(Resource("https://github.com/guo-yong-zhi/Stuffing.jl/blob/main/res/gradient.png?raw=true"))
"""

# ╔═╡ 14e1680e-c670-40a0-85ce-b5c1b8b79408
md"""
For detailed information about the algorithm implementation, please refer to our [`Stuffing.jl`](https://github.com/guo-yong-zhi/Stuffing.jl) package. It is entirely implemented in Julia, fully leveraging the advantages of the language.
"""

# ╔═╡ a5b14181-6b86-459a-888a-86525549003e


# ╔═╡ 610c2181-3cea-4b4e-91d1-98aa3bc3f40e
md"Now we are familiar with the algorithm. let's make an application based on it."

# ╔═╡ 0aeec0c5-fe8d-4d88-907f-ce4c064aae5a


# ╔═╡ bda3fa85-04a3-4033-9890-a5b4f10e2a77
begin
    logo = html"""<a href="https://github.com/guo-yong-zhi/WordCloud.jl"><img src="https://raw.githubusercontent.com/guo-yong-zhi/WordCloud.jl/master/docs/src/assets/logo.svg" alt="WordCloud" width=86></a>"""

    md"""$logo  **Data source:** $(@bind texttype Select(["Text", "File", "Web", "Table"]))　*You can directly input the text, or give a file, a table or even a website.*"""
end

# ╔═╡ e8fd9734-40da-4954-a7b1-6d62ae6ed4bc
md"We can set a maximum word limit, filter out short words, and apply a word blacklist. After that we get the words we want, wherewith the visualisation is performed."

# ╔═╡ 6b7b1da7-03dc-4815-9abf-b8eea410d2fd
md"**max word count:** $(@bind maxnum NumberField(1:5000, default=500))　　**shortest word:** $(@bind minlength NumberField(1:1000, default=1))"

# ╔═╡ 852810b2-1830-4100-ad74-18b8e96afafe
md"""
**word blacklist:** $(@bind wordblacklist_ TextField(default="")) $(@bind enablestopwords　　CheckBox(default=true))enable the built-in stop word list"""

# ╔═╡ 0dddeaf5-08c3-46d0-8a79-30b5ce42ef2b
begin
    wordblacklist = [wordblacklist_[i] for i in findall(r"[^\s,;，；、]+", wordblacklist_)]
    isempty(wordblacklist) ? md"*Add the words you want to exclude.*" : wordblacklist
end

# ╔═╡ b4ffc272-8625-49f5-bee6-6fbbf03f9005
md"""
Then we determine font sizes by word frequencies and lengths. This involves a scaling process using a mapping function and normalization using a combination of power mean and tan functions. The formula can be expressed as:

$\text{font\_size} = \frac{\text{scale(frequency)}}{\text{powermean}(1, \text{word\_length}, p=\tan(\text{balance\_degree} \times \pi / 2))}$
"""

# ╔═╡ dfe608b0-077c-437a-adf2-b1382a0eb4eb
begin
    weightscale_funcs = [
        identity => "linear",
        (√) => "√x",
        log1p => "log x",
        (n -> n^2) => "x²",
        expm1 => "exp x",
    ]
    md"**scale:** $(@bind rescale_func Select(weightscale_funcs))　　**word length balance:** $(@bind word_length_balance Slider(-1:0.01:1, default=0, show_value=true))"
end

# ╔═╡ b199e23c-de37-4bcf-b563-70bccb59ba4e
md"""###### ✿ Overall Layout
There are two styles of word distribution, as illustrated in the previous section: uniform and gathering. In addition, text density and spacing between words can also influence the overall layout appearance."""

# ╔═╡ 6e614caa-38dc-4028-b0a7-05f7030d5b43
md"**layout style:** $(@bind style Select([:auto, :uniform, :gathering]))"

# ╔═╡ 1e8947ee-5f2a-4bed-99d5-f24ebc6cfbf3
md"""**text density:** $(@bind density NumberField(0.1:0.01:10.0, default=0.5))　　**min word spacing:** $(@bind spacing NumberField(0:100, default=2))"""

# ╔═╡ 9bb3b69a-fd5b-469a-998f-23b6c9e23e5d
md"""###### ✿ Mask Style
The mask controls the shape of the gengerated word cloud and influences its appearance. To create a variety of masks, we utilize the powerful [`Luxor.jl`](https://github.com/JuliaGraphics/Luxor.jl) package."""

# ╔═╡ f4844a5f-260b-4713-84bf-69cd8123c7fc
md"""**mask shape:** $(@bind mask_ Select([:auto, :customsvg, box, ellipse, squircle, ngon, star, bezingon, bezistar])) $(@bind configshape　　CheckBox(default=false))additional config

**mask size:** $(@bind masksize_ TextField(default="auto"))　*e.g. 400,300*"""

# ╔═╡ 1aa632dc-b3e8-4a9d-9b9e-c13cd05cf97e
begin
    defaultsvgstr = """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-6 h-6">
      <path d="M11.645 20.91l-.007-.003-.022-.012a15.247 15.247 0 01-.383-.218 25.18 25.18 0 01-4.244-3.17C4.688 15.36 2.25 12.174 2.25 8.25 2.25 5.322 4.714 3 7.688 3A5.5 5.5 0 0112 5.052 5.5 5.5 0 0116.313 3c2.973 0 5.437 2.322 5.437 5.25 0 3.925-2.438 7.111-4.739 9.256a25.175 25.175 0 01-4.244 3.17 15.247 15.247 0 01-.383.219l-.022.012-.007.004-.003.001a.752.752 0 01-.704 0l-.003-.001z" />
    </svg>
    """
    if mask_ == :auto
        md"""**upload an image as a mask:** $(@bind uploadedmask FilePicker([MIME("image/*")]))"""
    elseif mask_ == :customsvg
        md"""**svg string:**　*For example, you can copy svg code from [here](https://heroicons.com/). You should choose a solid type icon.*

        $(@bind masksvgstr TextField((55, 2), default=defaultsvgstr))"""
    elseif configshape
        if mask_ in (ngon, star, bezingon, bezistar)
            md"**number of points:** $(@bind npoints NumberField(3:100, default=5))"
        elseif mask_ == squircle
            md"**shape parameter:** $(@bind rt NumberField(0.:0.5:3., default=0.))　*0: rectangle; 1: ellipse; 2: rhombus*; >2: four-armed star"
        else
            md"🛈 random $(mask_ isa Function ? nameof(mask_) : mask_) shape in use"
        end
    else
        md"🛈 random $(mask_ isa Function ? nameof(mask_) : mask_) shape in use"
    end
end

# ╔═╡ a90b83ca-384d-4157-99b3-df15764a242f
md"""**mask color:** $(@bind maskcolor_ Select([:auto, :default, :original, "custom color"], default=:default))　　**background color:** $(@bind backgroundcolor_ Select([:auto, :default, :original, :maskcolor, "custom color"], default=:default))　 $(@bind showbackground CheckBox(default=true))show background"""

# ╔═╡ 1842a3c8-4b47-4d36-a4e4-9a5ff4df452e
if maskcolor_ == "custom color"
    if backgroundcolor_ == "custom color"
        r = md"""**mask color:** $(@bind maskcolor ColorStringPicker())　　**background color:** $(@bind backgroundcolor ColorStringPicker())"""
    else
        backgroundcolor = backgroundcolor_
        r = md"""**mask color:** $(@bind maskcolor ColorStringPicker())"""
    end
else
    maskcolor = maskcolor_
    if backgroundcolor_ == "custom color"
        r = md"""**background color:** $(@bind backgroundcolor ColorStringPicker())"""
    else
        backgroundcolor = backgroundcolor_
        md"🛈 random mask color and background color in use"
    end
end


# ╔═╡ b38c3ad9-7885-4af6-8394-877fde8ed83b
md"**mask outline:** $(@bind outlinewidth NumberField(-1:100, default=-1))　*-1 means random*"

# ╔═╡ bd801e34-c012-4afc-8100-02b5e06d4e2b
md"""###### ✿ Text Style
Customize fonts, colors, and text orientations."""

# ╔═╡ 26d6b795-1cc3-4548-aa07-86c2f6ee0776
md"""**text fonts:** $(@bind fonts_ TextField(default="auto"))　*Use commas to separate multiple fonts.*"""

# ╔═╡ 7993fd44-2fcf-488e-9280-4b4d0bf0e22c
md"""
**text orientations:** $(@bind anglelength NumberField(0:1000, default=0)) orientations　*0 means random*
"""

# ╔═╡ 8153f1f1-9704-4b1e-bff9-009a54404448
if anglelength > 0
    md"""from $(@bind anglestart NumberField(-360:360, default=0)) degrees to $(@bind anglestop NumberField(-360:360, default=0)) degrees"""
else
    md"🛈 random text orientations in use"
end

# ╔═╡ 14666dc2-7ae4-4808-9db3-456eb26cd435
md"**text colors:** $(@bind colors_ Select([:auto; WordCloud.Schemes])) $(@bind colorstyle Select([:random, :gradient]))　[*Browse colorschemes in `ColorSchemes.jl`*](https://juliagraphics.github.io/ColorSchemes.jl/stable/catalogue)"

# ╔═╡ 2870a2ee-aa99-48ec-a26d-fed7b040e6de
@bind go Button("    🎲 Try again !    ")

# ╔═╡ 21ba4b81-07aa-4828-875d-090e0b918c76
begin
    defaulttext = """
    A word cloud (tag cloud or wordle) is a novelty visual representation of text data, 
    typically used to depict keyword metadata (tags) on websites, or to visualize free form text. 
    Tags are usually single words, and the importance of each tag is shown with font size or color. Bigger term means greater weight. 
    This format is useful for quickly perceiving the most prominent terms to determine its relative prominence.  
    """
    defaultttable = """
        বাংলা, 234
        भोजपुरी, 52.3
        مصري, 77.4
        English, 380
        Français, 80.8
        ગુજરાતી, 57.1
        هَوْسَ, 51.7
        हिन्दी, 345
        فارسی, 57.2
        Italiano, 64.6
        日本語, 123
        ꦧꦱꦗꦮ, 68.3
        한국어, 81.7
        普通话, 939
        मराठी, 83.2
        Português, 236
        Русский, 147
        Español, 485
        Deutsch, 75.3
        தமிழ், 78.6
        తెలుగు, 83
        Türkçe, 84
        اردو, 70.6
        Tiếng Việt, 85
        پنجابی, 66.7
        吴语, 83.4
        粤语, 86.1
        """
    nothing
end

# ╔═╡ 9191230b-b72a-4707-b7cf-1a51c9cdb217
if texttype == "Web"
    md"""🌐 $(@bind url TextField(70, default="https://help.juliahub.com/juliahub/stable/pluto2023"))  
    
    ( If you don't know what to fill in, give *http://en.wikipedia.org/wiki/Special:random* a shot. )  

    We retrieve the html content using the [`HTTP.jl`](https://github.com/JuliaWeb/HTTP.jl) package and then convert it into plain text.
    """
elseif texttype == "Text"
    @bind text_ TextField((55, 10), defaulttext)
elseif texttype == "File"
    @bind uploadedfile FilePicker()
else
    md"""
    *The first column contains words, the second column contains weights.*
	
    $(@bind text_ TextField((20, 15), defaultttable))
    """
end

# ╔═╡ 66f4b71e-01e5-4279-858b-04d44aeeb574
begin
    function read_table(text)
        ps = [split(it, r"[,;\t]") for it in split(strip(text), "\n")]
        ps = sort([(first(it), parse(Float64, last(it))) for it in ps], by=last, rev=true)
        maxwidth = maximum(length ∘ first, ps[1:min(end, 9)])
        println(length(ps), " items table:\n")
        for (i, p) in enumerate(ps)
            if i == 10
                println("\t...")
                break
            end
            println("\t", p[1], " "^(maxwidth - length(p[1])) * "\t|\t", p[end])
        end
        println()
        ps
    end
    nothing
end

# ╔═╡ 397fdd42-d2b2-46db-bf74-957909f47a58
begin
    function svgshapemask(svgstr, masksize; preservevolume=true, kargs...)
        ags = [string(masksize), "preservevolume=$preservevolume", ("$k=$(repr(v))" for (k, v) in kargs)...]
        println("svgshapemask(", join(ags, ", "), ")")
        masksvg = WordCloud.Render.loadsvg(masksvgstr)
        vf = preservevolume ? WordCloud.volume_factor(masksvg) : 1
        resizedsvg = WordCloud.Render.imresize(masksvg, masksize...; ratio=vf)
        loadmask(WordCloud.Render.tobitmap(resizedsvg); kargs...)
    end
    svgshapefunc(svgstr) = (a...; ka...) -> svgshapemask(svgstr, a...; ka...)
    if mask_ == :auto
        if uploadedmask === nothing
            mask = :auto
            nothing
        else
            mask = loadmask(IOBuffer(uploadedmask["data"]))
            nothing
        end
    elseif mask_ == :customsvg
        mask = svgshapefunc(masksvgstr)
        nothing
    else
        mask = mask_
        nothing
    end
end

# ╔═╡ 74bd4779-c13c-4d16-a90d-597db21eaa39
begin
    maskkwargs = (;)
    if configshape
        if mask in (ngon, star, bezingon, bezistar)
            maskkwargs = (npoints=npoints,)
        elseif mask == squircle
            maskkwargs = (rt=rt,)
        end
    end
    nothing
end

# ╔═╡ 9396cf96-d553-43db-a839-273fc9febd5a
begin
    angles = :auto
    try
        global angles = range(anglestart, anglestop, length=anglelength)
        isempty(angles) && (angles = :auto)
        nothing
    catch
    end
end

# ╔═╡ 1a4d1e62-6a41-4a75-a759-839445dacf4f
begin
    if fonts_ == "auto"
        fonts = Symbol(fonts_)
    elseif fonts_ === nothing
        fonts = ""
    elseif occursin(",", fonts_)
        fonts = tuple(split(fonts_, ",")...)
    else
        fonts = fonts_
    end
    nothing
end


# ╔═╡ b09620ef-4495-4c83-ad1c-2d8b0ed70710
begin
    function ischinese(text::AbstractString)
        ch = 0
        total = 0
        for c in text
            if match(r"\w", string(c)) !== nothing
                total += 1
                if '\u4e00' <= c <= '\u9fa5'
                    ch += 1
                end
            end
        end
        if total > 0
            # println("total: $total; chinese: $ch; ratio: $(ch/total)")
            return ch / total > 0.05
        else
            return false
        end
    end

    function wordseg_cn(t)
        jieba = pyimport("jieba")
        pyconvert(Vector{String}, jieba.lcut(t))
    end
    nothing
end

# ╔═╡ d8e73850-f0a6-4170-be45-5a7527f1ec39
begin
    function text_from_url(url)
        resp = HTTP.request("GET", url, redirect=true)
        println(resp.request)
        resp.body |> String |> html2text
    end
    go
    words_weights = ([], [])
    wordsnum = 0
    try
        if texttype == "Web"
            if !isempty(url)
                text = text_from_url(url)
            end
        elseif texttype == "Text"
            text = text_
        elseif texttype == "File"
            if uploadedfile !== nothing
                text = read(IOBuffer(uploadedfile["data"]), String)
            end
        else
            text = read_table(text_)
        end
        dict_process = rescaleweights(rescale_func, tan(word_length_balance * π / 2)) ∘ casemerge! ∘ lemmatize!
        if text isa AbstractString && ischinese(text)
            println("检测到中文")
            text = wordseg_cn(text)
        end
        global words_weights = processtext(
            text, maxnum=maxnum,
            minlength=minlength,
            stopwords=enablestopwords ? WordCloud.stopwords ∪ wordblacklist : wordblacklist,
            process=dict_process)
        global wordsnum = length(words_weights[1])
    catch e
        # rethrow(e)
    end
    md"""###### ✿ Text Processing
    We plan to support both English and Chinese. English text can be easily split using spaces, while Chinese word segmentation is more challenging. To address this, we utilize [`PythonCall.jl`](https://github.com/cjdoris/PythonCall.jl) to call [`jieba`](https://github.com/fxsjy/jieba), which effectively handles Chinese word segmentation for us."""
end

# ╔═╡ 77e13474-8987-4cc6-93a9-ea68ca53b217
begin
    colors__ = colors_
    if colorstyle == :gradient
        if colors__ == :auto
            colors__ = rand(WordCloud.Schemes)
        end
        md"""
        **gradient range:** $(@bind colorstart NumberField(0.:0.01:1., default=0.)) to $(@bind colorstop NumberField(0.:0.01:1., default=1.)). $wordsnum colors of $colors__   
        """
    else
        if colors__ == :auto
            md"🛈 random color scheme in use"
        else
            md"**sampling probability:** $(@bind colorprob NumberField(0.1:0.01:1., default=0.5))"
        end
    end
end

# ╔═╡ a758178c-b6e6-491c-83a3-8b3fa594fc9e
begin
    colors = colors__
    if colors != :auto
        C = WordCloud.colorschemes[colors]
        if colorstyle == :random
            colors_vec = WordCloud.randsubseq(C.colors, colorprob)
            isempty(colors_vec) && (colors_vec = C.colors)
            colors = tuple(colors_vec...)
            colors_vec
        elseif colorstyle == :gradient
            colors = WordCloud.gradient(words_weights[end], scheme=colors, section=(colorstart, max(colorstart, colorstop)))
        else
            C
        end
    else
        md""
    end
end

# ╔═╡ fa6b3269-357e-4bf9-8514-70aff9df427f
begin
    function gen_cloud(words_weights)
        if outlinewidth isa Number && outlinewidth >= 0
            olw = outlinewidth
        else
            olw = rand((0, 0, 0, rand(2:10)))
        end
        masksize = :auto
        try
            masksize = Tuple(parse(Int, i) for i in split(masksize_, ","))
            if length(masksize) == 1
                masksize = masksize[1]
            end
        catch
        end
        try
            return wordcloud(
                words_weights;
                colors=colors,
                angles=angles,
                fonts=fonts,
                mask=mask,
                masksize=masksize,
                maskcolor=maskcolor,
                backgroundcolor=backgroundcolor,
                outline=olw,
                density=density,
                spacing=spacing,
                style=style,
                maskkwargs...
            ) |> generate!
        catch e
            # rethrow(e)
        end
        return nothing
    end
    @time wc = gen_cloud(words_weights)
    if wc !== nothing
        paintsvg(wc, background=showbackground)
    end
end


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CondaPkg = "992eb4ea-22a4-4c89-a5bb-47a3300528ab"
Downloads = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
Fontconfig_jll = "a3f928ae-7b40-5064-980b-68af3947d34b"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
ImageIO = "82e4d734-157c-48bb-816b-45c225c6df19"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
PythonCall = "6099a3de-0909-46bc-b1f4-468b9a2dfc0d"
WordCloud = "6385f0a0-cb03-45b6-9089-4e0acc74b26b"

[compat]
CondaPkg = "~0.2.18"
Fontconfig_jll = "~2.13.93"
HTTP = "~1.9.14"
ImageIO = "~0.6.7"
PlutoUI = "~0.7.52"
PythonCall = "~0.9.13"
WordCloud = "~0.12.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.2"
manifest_format = "2.0"
project_hash = "34ce415c28a6895db2f2a166ab1ef3f09ff93b90"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "cad4c758c0038eea30394b1b671526921ca85b21"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.4.0"
weakdeps = ["ChainRulesCore"]

    [deps.AbstractFFTs.extensions]
    AbstractFFTsChainRulesCoreExt = "ChainRulesCore"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "91bd53c39b9cbfb5ef4b015e8b582d344532bd0a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.2.0"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "76289dc51920fdc6e0013c872ba9551d54961c24"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.6.2"
weakdeps = ["StaticArrays"]

    [deps.Adapt.extensions]
    AdaptStaticArraysExt = "StaticArrays"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "16351be62963a67ac4083f748fdb3cca58bfd52f"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.7"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitFlags]]
git-tree-sha1 = "43b1a4a8f797c1cddadf60499a8a077d4af2cd2d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.7"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CEnum]]
git-tree-sha1 = "eb4cb44a499229b3b8426dcfb5dd85333951ff90"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.2"

[[deps.Cairo]]
deps = ["Cairo_jll", "Colors", "Glib_jll", "Graphics", "Libdl", "Pango_jll"]
git-tree-sha1 = "d0b3f8b4ad16cb0a2988c6788646a5e6a17b6b1b"
uuid = "159f3aea-2a34-519c-b102-8c37f9878175"
version = "1.0.5"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "e30f2f4e20f7f186dc36529910beaedc60cfa644"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.16.0"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "02aa26a4cf76381be7f66e020a3eddeb27b0a092"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.2"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "dd3000d954d483c1aad05fe1eb9e6a715c97013e"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.22.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

    [deps.ColorVectorSpace.weakdeps]
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "5ce999a19f4ca23ea484e92a1774a61b8ca4cf8e"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.8.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+0"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "5372dbbf8f0bdb8c700db5367132925c0771ef7e"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.2.1"

[[deps.CondaPkg]]
deps = ["JSON3", "Markdown", "MicroMamba", "Pidfile", "Pkg", "TOML"]
git-tree-sha1 = "741146cf2ced5859faae76a84b541aa9af1a78bb"
uuid = "992eb4ea-22a4-4c89-a5bb-47a3300528ab"
version = "0.2.18"

[[deps.CoordinateTransformations]]
deps = ["LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "f9d7112bfff8a19a3a4ea4e03a8e6a91fe8456bf"
uuid = "150eb455-5306-5404-9cee-2592286d6298"
version = "0.6.3"

[[deps.DataAPI]]
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "cf25ccb972fec4e4817764d01c82386ae94f77b4"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.14"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "e90caa41f5a86296e014e148ee061bd6c3edec96"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.9"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "4558ab818dcceaab612d1bb8c19cee87eda2b83c"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.5.0+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Pkg", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "74faea50c1d007c85837327f6775bea60b5492dd"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.2+2"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "299dc33549f68299137e51e6d49a13b5b1da9673"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.16.1"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "d8db6a5a2fe1381c1ea4ef2cab7c69c2de7f9ea0"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.1+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "d3b3624125c1474292d0d8ed0f65554ac37ddb23"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.74.0+2"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "d61890399bc535850c4bf08e4e0d3a7ad0f21cbd"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.2"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "cb56ccdd481c0dd7f975ad2b3b62d9eda088f7e2"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.9.14"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "d75853a0bdbfb1ac815478bacd89cd27b550ace6"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.3"

[[deps.ImageAxes]]
deps = ["AxisArrays", "ImageBase", "ImageCore", "Reexport", "SimpleTraits"]
git-tree-sha1 = "2e4520d67b0cef90865b3ef727594d2a58e0e1f8"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.11"

[[deps.ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "eb49b82c172811fd2c86759fa0553a2221feb909"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.7"

[[deps.ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "PrecompileTools", "Reexport"]
git-tree-sha1 = "fc5d1d3443a124fde6e92d0260cd9e064eba69f8"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.10.1"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs"]
git-tree-sha1 = "bca20b2f5d00c4fbc192c3212da8fa79f4688009"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.7"

[[deps.ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "355e2b974f2e3212a75dfb60519de21361ad3cb7"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.9"

[[deps.ImageTransformations]]
deps = ["AxisAlgorithms", "CoordinateTransformations", "ImageBase", "ImageCore", "Interpolations", "OffsetArrays", "Rotations", "StaticArrays"]
git-tree-sha1 = "7ec124670cbce8f9f0267ba703396960337e54b5"
uuid = "02fcd773-0e25-5acc-982a-7f6622650795"
version = "0.10.0"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "3d09a9f60edf77f8a4d99f9e015e8fbf9989605d"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.7+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "5cd07aab533df5170988219191dfad0519391428"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.3"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "721ec2cf720536ad005cb38f50dbba7b02419a15"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.14.7"

[[deps.IntervalSets]]
deps = ["Dates", "Random", "Statistics"]
git-tree-sha1 = "16c0cc91853084cb5f58a78bd209513900206ce6"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.4"

[[deps.IterTools]]
git-tree-sha1 = "4ced6667f9974fc5c5943fa5e2ef1ca43ea9e450"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.8.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JSON3]]
deps = ["Dates", "Mmap", "Parsers", "PrecompileTools", "StructTypes", "UUIDs"]
git-tree-sha1 = "5b62d93f2582b09e469b3099d839c2d2ebf5066d"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.13.1"

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "327713faef2a3e5c80f96bf38d1fa26f7a6ae29e"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.3"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6f2675ef130a300a112286de91973805fcc5ffbc"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.91+0"

[[deps.Juno]]
deps = ["Base64", "Logging", "Media", "Profile"]
git-tree-sha1 = "07cb43290a840908a771552911a6274bc6c072c7"
uuid = "e5e0dc1b-0480-54bc-9374-aad01c23163d"
version = "0.8.4"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f689897ccbe049adb19a065c495e75f372ecd42b"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "15.0.4+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c7cb1f5d892775ba13767a87c7ada0b980ea0a71"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+2"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Librsvg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pango_jll", "Pkg", "gdk_pixbuf_jll"]
git-tree-sha1 = "ae0923dab7324e6bc980834f709c4cd83dd797ed"
uuid = "925c91fb-5dd6-59dd-8e8c-345e74382d89"
version = "2.54.5+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "cedb76b37bc5a6c702ade66be44f831fa23c681e"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.0"

[[deps.Luxor]]
deps = ["Base64", "Cairo", "Colors", "Dates", "FFMPEG", "FileIO", "Juno", "LaTeXStrings", "Random", "Requires", "Rsvg", "SnoopPrecompile"]
git-tree-sha1 = "909a67c53fddd216d5e986d804b26b1e3c82d66d"
uuid = "ae8d54c2-7ccd-5906-9d76-62fc9837b5bc"
version = "3.7.0"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "42324d08725e200c23d4dfb549e0d5d89dede2d2"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.10"

[[deps.MappedArrays]]
git-tree-sha1 = "2dab0221fe2b0f2cb6754eaa743cc266339f527e"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.2"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "Random", "Sockets"]
git-tree-sha1 = "03a9b9718f5682ecb107ac9f7308991db4ce395b"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.7"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

[[deps.Media]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "75a54abd10709c01f1b86b84ec225d26e840ed58"
uuid = "e89f7d12-3494-54d1-8411-f7d8b9ae1f27"
version = "0.5.0"

[[deps.MicroMamba]]
deps = ["Pkg", "Scratch", "micromamba_jll"]
git-tree-sha1 = "6f0e43750a94574c18933e9456b18d4d94a4a671"
uuid = "0b3b1443-0f03-428d-bdfb-f27f9c1191ea"
version = "0.1.13"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "7b86a5d4d70a9f5cdf2dacb3cbe6d251d1a61dbe"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.4"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore", "ImageMetadata"]
git-tree-sha1 = "d92b107dbb887293622df7697a2223f9f8176fcd"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.1.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "2ac17d29c523ce1cd38e27785a7d23024853a4bb"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.10"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "327f53360fdb54df7ecd01e96ef1983536d1e633"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.2"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "a4ca623df1ae99d09bc9868b008262d0c0ac1e4f"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.1.4+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "51901a49222b09e3743c65b8847687ae5fc78eb2"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.1"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1aa4b74f80b01c6bc2b89992b861b5f210e665b5"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.21+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "2e73fe17cac3c62ad1aebe70d44c963c3cfdc3e3"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.2"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+0"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "9b02b27ac477cad98114584ff964e3052f656a0f"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.4.0"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "0fac6313486baae819364c52b4f483450a9d793f"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.12"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "84a314e3926ba9ec66ac097e3635e270986b0f10"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.50.9+0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "4b2e829ee66d4218e0cef22c0a64ee37cf258c29"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.7.1"

[[deps.Pidfile]]
deps = ["FileWatching", "Test"]
git-tree-sha1 = "2d8aaf8ee10df53d0dfb9b8ee44ae7c04ced2b03"
uuid = "fa939f87-e72e-5be4-a000-7fc836dbe307"
version = "1.3.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "64779bc4c9784fee475689a1752ef4d5747c5e87"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.42.2+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.2"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "f6cf8e7944e50901594838951729a1861e668cb8"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.3.2"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "e47cd150dbe0443c3a3651bc5b9cbd5576ab75b7"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.52"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "9673d39decc5feece56ef3940e5dafba15ba0f81"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.1.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "7eb1686b4f04b82f96ed7a4ea5890a4f0c7a09f1"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "d7a7aef8f8f2d537104f170139553b14dfe39fe9"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.2"

[[deps.PythonCall]]
deps = ["CondaPkg", "Dates", "Libdl", "MacroTools", "Markdown", "Pkg", "REPL", "Requires", "Serialization", "Tables", "UnsafePointers"]
git-tree-sha1 = "0d15cb32f52654921169b4305dae8f66a0e345dc"
uuid = "6099a3de-0909-46bc-b1f4-468b9a2dfc0d"
version = "0.9.13"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "18e8f4d1426e965c7b532ddd260599e1510d26ce"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.0"

[[deps.Quaternions]]
deps = ["LinearAlgebra", "Random", "RealDot"]
git-tree-sha1 = "da095158bdc8eaccb7890f9884048555ab771019"
uuid = "94ee1d12-ae83-5a48-8b1c-48b8ff168ae0"
version = "0.7.4"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "1342a47bf3260ee108163042310d26f2be5ec90b"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.5"
weakdeps = ["FixedPointNumbers"]

    [deps.Ratios.extensions]
    RatiosFixedPointNumbersExt = "FixedPointNumbers"

[[deps.RealDot]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9f0a1b71baaf7650f4fa8a1d168c7fb6ee41f0c9"
uuid = "c1ae055f-0cd5-4b69-90a6-9a35b1a98df9"
version = "0.1.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rotations]]
deps = ["LinearAlgebra", "Quaternions", "Random", "StaticArrays"]
git-tree-sha1 = "54ccb4dbab4b1f69beb255a2c0ca5f65a9c82f08"
uuid = "6038ab10-8711-5258-84ad-4b1120ba62dc"
version = "1.5.1"

[[deps.Rsvg]]
deps = ["Cairo", "Glib_jll", "Librsvg_jll"]
git-tree-sha1 = "3d3dc66eb46568fb3a5259034bfc752a0eb0c686"
uuid = "c4c386cf-5103-5370-be45-f3a111cca3b8"
version = "1.0.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "30449ee12237627992a99d5e30ae63e4d78cd24a"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "2da10356e31327c7096832eb9cd86307a50b1eb6"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.3"

[[deps.SnoopPrecompile]]
deps = ["Preferences"]
git-tree-sha1 = "e760a70afdcd461cf01a575947738d359234665c"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore"]
git-tree-sha1 = "9cabadf6e7cd2349b6cf49f1915ad2028d65e881"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.6.2"
weakdeps = ["Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysStatisticsExt = "Statistics"

[[deps.StaticArraysCore]]
git-tree-sha1 = "36b3d696ce6366023a0ea192b4cd442268995a0d"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.2"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "ca4bccb03acf9faaf4137a9abc1881ed1841aa70"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.10.0"

[[deps.Stuffing]]
deps = ["Random"]
git-tree-sha1 = "6dd0909e93478b31579baf120a3ab15bf7aa9a7c"
uuid = "4175e07e-e5b7-423e-8796-3ea7f6d48281"
version = "0.10.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "1544b926975372da01227b382066ab70e574a3ec"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "ProgressMeter", "UUIDs"]
git-tree-sha1 = "8621f5c499a8aa4aa970b1ae381aae0ef1576966"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.6.4"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "9a6ae7ed916312b41236fcef7e0af564ef934769"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.13"

[[deps.Tricks]]
git-tree-sha1 = "aadb748be58b492045b4f56166b5188aa63ce549"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.7"

[[deps.URIs]]
git-tree-sha1 = "074f993b0ca030848b897beff716d93aca60f06a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.2"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnsafePointers]]
git-tree-sha1 = "c81331b3b2e60a982be57c046ec91f599ede674a"
uuid = "e17b2a0c-0bdf-430a-bd0c-3a23cae4ff39"
version = "1.0.0"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[deps.WordCloud]]
deps = ["ColorSchemes", "Colors", "FileIO", "ImageTransformations", "Luxor", "Printf", "Random", "Statistics", "Stuffing"]
git-tree-sha1 = "b465465dbc6e4a898fde2aa3a2c903c8a0dd5ba7"
uuid = "6385f0a0-cb03-45b6-9089-4e0acc74b26b"
version = "0.12.1"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "93c41695bc1c08c46c5899f4fe06d6ead504bb73"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.10.3+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "afead5aba5aa507ad5a3bf01f58f82c8d1403495"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.6+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6035850dcc70518ca32f012e46015b9beeda49d8"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.11+0"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "34d526d318358a859d7de23da945578e8e8727b7"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.4+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8fdda4c692503d44d04a0603d9ac0982054635f9"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.1+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "b4bfde5d5b652e22b9c790ad00af08b6d042b97d"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.15.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e92a1a012a10506618f10b7047e478403a046c77"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.5.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "49ce682769cd5de6c72dcf1b94ed7790cd08974c"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.5+0"

[[deps.gdk_pixbuf_jll]]
deps = ["Artifacts", "Glib_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg", "Xorg_libX11_jll", "libpng_jll"]
git-tree-sha1 = "e9190f9fb03f9c3b15b9fb0c380b0d57a3c8ea39"
uuid = "da03df04-f53b-5353-a52f-6a8b0620ced0"
version = "2.42.8+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "libpng_jll"]
git-tree-sha1 = "d4f63314c8aa1e48cd22aa0c17ed76cd1ae48c3c"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.10.3+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.micromamba_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl"]
git-tree-sha1 = "087555b0405ed6adf526cef22b6931606b5af8ac"
uuid = "f8abcde7-e9b7-5caa-b8af-a437887ae8e4"
version = "1.4.1+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"
"""

# ╔═╡ Cell order:
# ╟─10b8d675-ee35-46dd-aee7-6792749d16f2
# ╟─e4ab8ddd-0486-420d-a90d-e57714ef02de
# ╟─4b5544d3-230f-499f-94b1-dd05f595ef88
# ╟─ffa6f9f4-0a00-409c-a4c3-b00a0060877f
# ╟─04a2b044-3e90-4c22-a2af-143f5476b6c8
# ╟─c51883b6-5ef6-4a78-bdc2-b39e49403ecf
# ╟─a186a333-3f34-4973-a1b0-d7cdc6394c3c
# ╟─e5d15923-9a17-493d-b2af-244509e1e3ba
# ╟─b5c9984a-3829-4fd8-9722-99f45806745b
# ╟─3826a575-abef-4633-93ee-78a299da9998
# ╟─0e5f246d-aae1-4c4d-b6cd-92b2d2f617f9
# ╟─f2dda08e-ad06-49a6-b867-df2a16393a36
# ╟─638fa2aa-24c4-4867-ad2b-aa9e800fe324
# ╟─024a576b-a38d-4eac-bf90-537c46a0be90
# ╟─13d75a82-7983-44c0-b367-563ef338a066
# ╟─2d30826d-5730-4f58-9c01-09f7c4aeb54d
# ╟─a3b208a3-20c0-439e-96fd-10b0e5cc188a
# ╟─b7c1e2a5-d5ae-4e97-a1b0-a9f2d99a1100
# ╟─14e1680e-c670-40a0-85ce-b5c1b8b79408
# ╟─a5b14181-6b86-459a-888a-86525549003e
# ╟─610c2181-3cea-4b4e-91d1-98aa3bc3f40e
# ╟─0aeec0c5-fe8d-4d88-907f-ce4c064aae5a
# ╟─bda3fa85-04a3-4033-9890-a5b4f10e2a77
# ╟─9191230b-b72a-4707-b7cf-1a51c9cdb217
# ╟─d8e73850-f0a6-4170-be45-5a7527f1ec39
# ╟─e8fd9734-40da-4954-a7b1-6d62ae6ed4bc
# ╟─6b7b1da7-03dc-4815-9abf-b8eea410d2fd
# ╟─852810b2-1830-4100-ad74-18b8e96afafe
# ╟─0dddeaf5-08c3-46d0-8a79-30b5ce42ef2b
# ╟─b4ffc272-8625-49f5-bee6-6fbbf03f9005
# ╟─dfe608b0-077c-437a-adf2-b1382a0eb4eb
# ╟─b199e23c-de37-4bcf-b563-70bccb59ba4e
# ╟─6e614caa-38dc-4028-b0a7-05f7030d5b43
# ╟─1e8947ee-5f2a-4bed-99d5-f24ebc6cfbf3
# ╟─9bb3b69a-fd5b-469a-998f-23b6c9e23e5d
# ╟─f4844a5f-260b-4713-84bf-69cd8123c7fc
# ╟─1aa632dc-b3e8-4a9d-9b9e-c13cd05cf97e
# ╟─a90b83ca-384d-4157-99b3-df15764a242f
# ╟─1842a3c8-4b47-4d36-a4e4-9a5ff4df452e
# ╟─b38c3ad9-7885-4af6-8394-877fde8ed83b
# ╟─bd801e34-c012-4afc-8100-02b5e06d4e2b
# ╟─26d6b795-1cc3-4548-aa07-86c2f6ee0776
# ╟─7993fd44-2fcf-488e-9280-4b4d0bf0e22c
# ╟─8153f1f1-9704-4b1e-bff9-009a54404448
# ╟─14666dc2-7ae4-4808-9db3-456eb26cd435
# ╟─77e13474-8987-4cc6-93a9-ea68ca53b217
# ╟─a758178c-b6e6-491c-83a3-8b3fa594fc9e
# ╟─2870a2ee-aa99-48ec-a26d-fed7b040e6de
# ╟─fa6b3269-357e-4bf9-8514-70aff9df427f
# ╟─21ba4b81-07aa-4828-875d-090e0b918c76
# ╟─66f4b71e-01e5-4279-858b-04d44aeeb574
# ╟─397fdd42-d2b2-46db-bf74-957909f47a58
# ╟─74bd4779-c13c-4d16-a90d-597db21eaa39
# ╟─9396cf96-d553-43db-a839-273fc9febd5a
# ╟─1a4d1e62-6a41-4a75-a759-839445dacf4f
# ╟─b09620ef-4495-4c83-ad1c-2d8b0ed70710
# ╟─daf38998-c448-498a-82e2-b48a6a2b9c27
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
