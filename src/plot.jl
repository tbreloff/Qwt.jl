
# NOTE: these can be standalone windows, or subplots within a Subplots window

abstract PlotWidget

type Plot <: PlotWidget
	widget::PyObject
	lines::Vector{PlotItem}
	numLeft::Int
	numRight::Int

	function Plot()
		widget = PLOT.BasicPlot()
		widget[:resize](800,600)
		new(widget, PlotItem[], 0, 0)
	end
end

Base.string(plt::Plot) = "Plot{lines=$(plt.lines)}"
Base.print(io::IO, plt::Plot) = print(io, string(plt))
Base.show(io::IO, plt::Plot) = print(io, string(plt))

function Base.push!(plt::Plot, idx::Int, x::Number, y::Number)
	push!(plt.lines[idx], x, y)
end

# add one data point for each line, all with the same x value
function Base.push!(plt::Plot, x::Number, ys::Vector)
	@assert length(ys) == length(plt.lines)
	for (i,y) in enumerate(ys)
		push!(plt.lines[i], x, y)
	end
end

# refreshes the plot object
function refresh(plt::Plot)

	plt.widget[:startUpdate]()

	for l in plt.lines
		ca = get(plt.widget[isleft(l) ? "curvesAxis1" : "curvesAxis2"], l.idx-1)
		updateWidgetData(l, ca)
		# ca[:setData](l.x, l.y)
	end
	
	plt.widget[:finishUpdate]()

	nothing
end

function Base.empty!(plt::Plot)
	for l in plt.lines
		empty!(l)
	end
end

getplot(plt::Plot, c::Int) = plt
getline(plt::Plot, c::Int) = plt.lines[c]



showwidget(plt::Plot) = showwidget(plt.widget)
hidewidget(plt::Plot) = hidewidget(plt.widget)
widgetpos(plt::Plot) = widgetpos(plt.widget)
widgetsize(plt::Plot) = widgetsize(plt.widget)
movewidget(plt::Plot, x::Int, y::Int) = movewidget(plt.widget, x, y)
resizewidget(plt::Plot, width::Int, height::Int) = resizewidget(plt.widget, width, height)
move_resizewidget(plt::Plot, x::Int, y::Int, width::Int, height::Int) = move_resizewidget(plt.widget, x, y, width, height)
savepng(plt::Plot, filename::String) = savepng(plt.widget, filename)

title(plt::Plot, title::String) = plt.widget[:setPlotTitle](title)
xlabel(plt::Plot, label::String) = plt.widget[:setXAxisTitle](label)
ylabel(plt::Plot, label::String) = plt.widget[:setYAxisTitle](label)
yrightlabel(plt::Plot, label::String) = plt.widget[:setYAxisTitleRight](label)
windowtitle(plt::Plot, title::String) = windowtitle(plt.widget, title)


########################################################################################

# kvs is a list of (key,value) tuples, where key is a Symbol.
# valid keys: 
#  	:x (can be vector, range, or matrix... if matrix, y must be matrix too, and nc must match)
#  	:y (can be vector, range, or matrix... if matrix, series must go down the columns)

# you can specify any of the following optional arguments
# Note they are all Symbol's (except label, which is a string)
# 	:axis, :color, :label, :linetype, :linestyle, :marker, :markercolor

# you can also specify lists of these values, 1 per series, by adding an s to the end of the symbol: 
#		:axiss, :colors, etc


const COLORS = [:black, :blue, :green, :red, :darkGray, :darkCyan, :darkYellow, :darkMagenta,
								:darkBlue, :darkGreen, :darkRed, :gray, :cyan, :yellow, :magenta]
const NUMCOLORS = length(COLORS)

# these are valid choices... first one is default value if unset
const LINE_AXES = (:left, :right)
const LINE_TYPES = (:line, :step, :stepinverted, :sticks, :dots, :none, :heatmap)
const LINE_STYLES = (:solid, :dash, :dot, :dashdot, :dashdotdot)
const LINE_MARKERS = (:none, :ellipse, :rect, :diamond, :utriangle, :dtriangle, :cross, :xcross, :star1, :star2, :hexagon)

const DEFAULT_axis = LINE_AXES[1]
const DEFAULT_color = :auto
const DEFAULT_label = "AUTO"
const DEFAULT_width = 2
const DEFAULT_linetype = LINE_TYPES[1]
const DEFAULT_linestyle = LINE_STYLES[1]
const DEFAULT_marker = LINE_MARKERS[1]
const DEFAULT_markercolor = :auto
const DEFAULT_markersize = 10
const DEFAULT_heatmap_n = 100
const DEFAULT_heatmap_c = (0.15, 0.5)

const DEFAULT_title = ""
const DEFAULT_xlabel = ""
const DEFAULT_ylabel = ""
const DEFAULT_yrightlabel = ""


makematrix(i::Int) = zeros(Float64, 0, i)
makematrix{T<:Number}(z::Matrix{T}) = convert(Matrix{Float64}, z)
makematrix{T<:Number}(z::Union(StepRange{T,T},UnitRange{T},FloatRange{T},Vector{T})) = convert(Matrix{Float64}, reshape(z, length(z), 1))
buildX(Y::Matrix{Float64}) = makematrix(1:size(Y,1))

makeplural(s::Symbol) = Symbol(string(s,"s"))
makedefault(s::Symbol) = Symbol(string("DEFAULT_",s))

# get the corresponding plural arg, or the regular arg, or the default
# example: if :colors is set, then grab the i_th color, otherwise if :color is set, return that color, otherwise return the default :auto
function getarg(s::Symbol, d::Dict, c::Int)
	plural = makeplural(s)
	if haskey(d, plural)
		return d[plural][c]
	end
	get(d, s, eval(makedefault(s)))
end

autocolor(idx::Integer) = COLORS[mod1(idx,NUMCOLORS)]

# add one line to plot
function addline(plt::Plot, x, y, axis::Symbol, color::Symbol, label::String, width::Int, linetype::Symbol,
																	 linestyle::Symbol, marker::Symbol, markercolor::Symbol, markersize::Int, 
																	 heatmap_n::Int, heatmap_c::Tuple{Float64,Float64},
																	 tit::String, xlab::String, ylab::String, yrightlab::String)
	
	leftaxis = axis == :left
	isheatmap = linetype == :heatmap

	if leftaxis
		plt.numLeft += 1
		idx = plt.numLeft
	else
		plt.numRight += 1
		idx = plt.numRight
	end

	color = (color == :auto ? autocolor(idx) : color)
	markercolor = (markercolor == :auto ? autocolor(idx) : markercolor)
	label = string(label == "AUTO" ? "y_$idx" : label, " ($(leftaxis ? "L" : "R"))")

	# check our inputs
	@assert color in COLORS
	@assert width > 0
	@assert markersize > 0
	@assert linetype in LINE_TYPES
	@assert linestyle in LINE_STYLES
	@assert marker in LINE_MARKERS
	@assert markercolor in COLORS
	@assert heatmap_n > 0
	@assert heatmap_c[1] >= 0.0 && heatmap_c[2] >= heatmap_c[1]

	# create a new plotitem
	plotitem = (isheatmap ? HeatMap(axis, label, idx, heatmap_n, plt) : Series(axis, label, idx, color, plt))

	setdata(plotitem, x, y)
	push!(plt.lines, plotitem)

	# println("addline: $plotitem $color $label $width $linetype $linestyle $marker $markercolor $markersize $heatmap_n $heatmap_c")

	tit != "" && title(plt, tit)
	xlab != "" && xlabel(plt, xlab)
	ylab != "" && ylabel(plt, ylab)
	yrightlab != "" && yrightlabel(plt, yrightlab)

	# add it to the figure
	if isheatmap
		plt.widget[:addHeatMap](leftaxis, string(label), heatmap_c...)
	else
		args = map(string, (color, label, linetype, linestyle, marker, markercolor))
		plt.widget[:addLine](leftaxis, width, markersize, args...)
	end

	plotitem
end


function addRegressionLine(line)
	x = [minimum(line.x), maximum(line.x)]
	reg = [line.x ones(length(line.x))] \ line.y
	y = reg[1] * x + reg[2]
	oplot(line.plt, x, y, label = split(line.label, " (")[1] * " REG", color = getreglinecolor(line), width = 3)
	nothing
end


oplot(plt::PlotWidget, y::AbstractArray; kvs...) = oplot(plt; y = y, kvs...)
oplot(plt::PlotWidget, x::AbstractArray, y::AbstractArray; kvs...) = oplot(plt; x = x, y = y, kvs...)
oplot(plt::PlotWidget, f::Function, x::AbstractArray; kvs...) = oplot(plt; x = x, y = map(f, x), kvs...)

# generic way to add to plot
function oplot(plotwidget::PlotWidget; kvs...)
	d = Dict(kvs)

	# create a Matrix{Float64} with series y's going down columns
	# NOTE: you can leave y out of the parameter list and instead set n=numberOfBlankSeries
	Y = makematrix(get(d, :y, get(d, :n, 0)))

	# create a Matrix{Float64} with series x's going down columns
	# X can have 1 column, in which case it is reused for each series
	X = makematrix(get(d, :x, buildX(Y)))

	# duplicate the column of Y to match the columns of X
	xcols = size(X,2)
	ycols = size(Y,2)
	if xcols > 1 && ycols == 1
		Y = repmat(Y, 1, xcols)
	end

	if haskey(d, :windowtitle)
		windowtitle(plotwidget, d[:windowtitle])
	end

	for c in 1:ycols
		x = X[:,(xcols==1 ? 1 : c)]
		plt = getplot(plotwidget, c)  # get the correct Plot... nop when plotwidget is Plot, gets sp.plots[c] if MySubplot
		if isempty(x)
			continue
		end
		
		line = addline(plt, x, Y[:,c], [getarg(s,d,c) for s in (:axis, :color, :label, :width, :linetype, :linestyle, :marker, :markercolor, :markersize, :heatmap_n, :heatmap_c, :title, :xlabel, :ylabel, :yrightlabel)]...)

		if haskey(d, :reg)
			addRegressionLine(line)
		end
	end

	refresh(plotwidget)
	plotwidget
end


plot(y::AbstractArray; kvs...) = plot(; y = y, kvs...)
plot(x::AbstractArray, y::AbstractArray; kvs...) = plot(; x = x, y = y, kvs...)
plot(f::Function, x::AbstractArray; kvs...) = plot(; x = x, y = map(f, x), kvs...)


function plot(; kvs...)
	plt = Plot()
	oplot(plt; kvs...)
	showwidget(plt)
	moveWindowToCenterScreen(plt)
	plt
end



scatter(args...; kwargs...) = plot(args...; kwargs..., linetype=:dots)
heatmap(args...; kwargs...) = plot(args...; kwargs..., linetype=:heatmap)
