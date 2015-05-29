
require("PyCall")


module TwoAxisPlot

# using Base: string, print, show
# import Base.string, Base.print, Base.show

scatter(args...; kwargs...) = plot(args...; kwargs..., linetype=:dots)
heatmap(args...; kwargs...) = plot(args...; kwargs..., linetype=:heatmap)

export plot,
			 oplot,
			 subplot,
			 scatter,
			 heatmap,
			 title,
			 xlabel,
			 ylabel,
			 yrightlabel,
			 windowtitle,
			 savepng

# This is a wrapper around python, which is in turn a wrapper around Qwt5's plotting

# ZOOMING
# click and drag with the left mouse button to select a rectangle to zoom into
# to undo 1 zoom, hold ALT and click the right mouse button
# to redo 1 zoom, hold SHIFT and click the right mouse button
# to reset the zoom stack, click the middle mouse button

# PANNING
# click and drag with the right mouse button



using PyCall


# QT initialization
@pyimport PyQt4.Qt as QT
@pyimport BasicPlot as PLOT
println("INITIALIZING TwoAxisPlot...")
pygui_start(:qt)
const QAPP = QT.QApplication([])


abstract PlotItem

########################################################################################

type MyLine <: PlotItem
	axis::Symbol
	label
	idx
	color
	mp # MyPlot
	x::Vector{Float64}
	y::Vector{Float64}

	function MyLine(axis::Symbol, label, idx, color, mp)
		@assert axis in (:left, :right)
		new(axis, label, idx, color, mp, zeros(0), zeros(0))
	end
end

Base.string(line::MyLine) = "MyLine{axis=$(line.axis) label=$(line.label) idx=$(line.idx) npoints=$(length(line.x))}"
Base.print(io::IO, line::MyLine) = print(io, string(line))
Base.show(io::IO, line::MyLine) = print(io, string(line))

isleft(line::MyLine) = line.axis == :left
isright(line::MyLine) = line.axis == :right


function adddata!(line::MyLine, x::Float64, y::Float64)
	push!(line.x, x)
	push!(line.y, y)
	nothing
end

function adddata!(line::MyLine, x::Number, y::Number)
	adddata!(line, convert(Float64, x), convert(Float64, y))
end

function setdata!(line::MyLine, x::Vector{Float64}, y::Vector{Float64})
	@assert length(x) == length(y)
	line.x = x
	line.y = y
end

updateData(line::MyLine, pyobj::PyObject) = pyobj[:setData](line.x, line.y)



########################################################################################

type MyHeatMap <: PlotItem
	axis::Symbol
	label
	idx
	x::Vector{Float64}
	y::Vector{Float64}
	recalcOnUpdate::Bool
	n::Int
	mp # MyPlot

	function MyHeatMap(axis::Symbol, label, idx, n, mp)
		@assert axis in (:left, :right)
		new(axis, label, idx, zeros(0), zeros(0), true, n, mp)
	end
end

Base.string(heatmap::MyHeatMap) = "MyHeatMap{axis=$(heatmap.axis) label=$(heatmap.label) idx=$(heatmap.idx) npoints=$(length(heatmap.x))}"
Base.print(io::IO, heatmap::MyHeatMap) = print(io, string(heatmap))
Base.show(io::IO, heatmap::MyHeatMap) = print(io, string(heatmap))

isleft(heatmap::MyHeatMap) = heatmap.axis == :left
isright(heatmap::MyHeatMap) = heatmap.axis == :right


function adddata!(heatmap::MyHeatMap, x::Float64, y::Float64)
	push!(heatmap.x, x)
	push!(heatmap.y, y)
	nothing
end

function adddata!(heatmap::MyHeatMap, x::Number, y::Number)
	adddata!(heatmap, convert(Float64, x), convert(Float64, y))
end

function setdata!(heatmap::MyHeatMap, x::Vector{Float64}, y::Vector{Float64})
	@assert length(x) == length(y)
	heatmap.x = x
	heatmap.y = y
end

function updateData(heatmap::MyHeatMap, pyobj::PyObject)
	if heatmap.recalcOnUpdate
		heatMapData = PLOT.HeatMapData(heatmap.x, heatmap.y, heatmap.n)
		pyobj[:setData](heatMapData)
		recalcOnUpdate = false
	end
end


########################################################################################

type MySubplots
	subplotWidget::PyObject
	plots  # expected: Vector{Union(Vector{MyPlot}, MyPlot)}
	n
	nrowsOverride
	ncolsOverride
	nrows
	ncols

	function MySubplots()
		subplotWidget = PLOT.SubplotWidget()
		subplotWidget[:resize](800,600)
		new(subplotWidget, [], 0, 0, 0)
	end
end

# nrows(sp::MySubplots) = sp.nrowsOverride == 0 ? round(Int, sqrt(sp.n)) : sp.nrowsOverride
# ncols(sp::MySubplots) = sp.ncolsOverride == 0 ? ceil(Int, sp.n / nrows(sp)) : sp.ncolsOverride
function updateGrid(sp::MySubplots)
	if sp.nrowsOverride == 0
		if sp.ncolsOverride == 0
			sp.nrows = round(Int, sqrt(sp.n))
			sp.ncols = ceil(Int, sp.n / sp.nrows)
		else
			sp.ncols = sp.ncolsOverride
			sp.nrows = ceil(Int, sp.n / sp.ncols)
		end
	else
		sp.nrows = sp.nrowsOverride
		sp.ncols = ceil(Int, sp.n / sp.nrows)
	end
end

function getMyPlot(sp::MySubplots, c::Int)
	while c > length(sp.plots)
		push!(sp.plots, MyPlot())
		sp.n += 1
		updateGrid(sp)
	end
	sp.plots[c]
end

# function addline(sp::MySubplots, args...)
# 	mp = MyPlot()
# 	line = addline(mp, args...)
# 	push!(sp.plots, mp)
# 	sp.n += 1
# 	updateGrid(sp)
# 	line
# end

function update!(sp::MySubplots)
	for fig in sp.plots
		update!(fig)
	end
	# figs = reshape([[mp.fig for mp in sp.plots], [PLOT.EmptyWidget() for i in 1:nrows(sp)*ncols(sp)-sp.n]], ncols(sp), nrows(sp))'
	figs = reshape([[mp.fig for mp in sp.plots] ; fill(nothing, sp.nrows*sp.ncols - sp.n)], sp.ncols, sp.nrows)'
	# println(figs)
	sp.subplotWidget[:addFigures](figs)
	nothing
end


subplot(y; kvs...) = subplot(; y = y, kvs...)
subplot(x, y; kvs...) = subplot(; x = x, y = y, kvs...)

function subplot(; kvs...)
	sp = MySubplots()
	
	d = Dict(kvs)
	sp.nrowsOverride = get(d, :nrows, 0)
	sp.ncolsOverride = get(d, :ncols, 0)

	oplot(sp; kvs...)
	sp.subplotWidget[:show]()
	moveWindowToCenterScreen(sp)
	sp
end

########################################################################################

function screengeometry()
	geom = QT.QDesktopWidget()[:screenGeometry]()
	geom[:x](), geom[:y](), geom[:width](), geom[:height]()
end

function widgetsize(widget)
	wsz = widget[:frameSize]()
	wsz[:width](), wsz[:height]()
end

function center(widget)
	sx, sy, sw, sh = screengeometry()
	fw, fh = widgetsize(widget)
	widget[:move](sw/2 - fw/2, sh/2 - fh-2)
	nothing
end

movetospecialspot(widget) = widget[:move](1920,20)


########################################################################################



type MyPlot
	fig::PyObject
	lines::Vector{PlotItem}
	numLeft::Int
	numRight::Int

	function MyPlot()
		fig = PLOT.BasicPlot()
		fig[:resize](800,600)
		new(fig, PlotItem[], 0, 0)
	end
end

Base.string(plt::MyPlot) = "MyPlot{lines=$(plt.lines)}"
Base.print(io::IO, plt::MyPlot) = print(io, string(plt))
Base.show(io::IO, plt::MyPlot) = print(io, string(plt))

# add one data point for each line, all with the same x value
function adddata!(mp::MyPlot, x, ys)
	@assert length(ys) == length(mp.lines)

	for (i,y) in enumerate(ys)
		adddata!(mp.lines[i], x, y)
	end
	nothing
end

# refreshes the plot object
function update!(mp::MyPlot)

	mp.fig[:startUpdate]()

	for l in mp.lines
		ca = get(mp.fig[isleft(l) ? "curvesAxis1" : "curvesAxis2"], l.idx-1)
		updateData(l, ca)
		# ca[:setData](l.x, l.y)
	end
	
	mp.fig[:finishUpdate]()

	nothing
end

getMyPlot(mp::MyPlot, c::Int) = mp



typealias PlotOrSubPlot Union(MyPlot, MySubplots)

showwidget(mp::MyPlot) = showwidget(mp.fig)
hidewidget(mp::MyPlot) = hidewidget(mp.fig)
widgetpos(mp::MyPlot) = widgetpos(mp.fig)
widgetsize(mp::MyPlot) = widgetsize(mp.fig)
movewidget(mp::MyPlot, x::Int, y::Int) = movewidget(mp.fig, x, y)
resizewidget(mp::MyPlot, width::Int, height::Int) = resizewidget(mp.fig, width, height)
move_resizewidget(mp::MyPlot, x::Int, y::Int, width::Int, height::Int) = move_resizewidget(mp.fig, x, y, width, height)
savepng(mp::MyPlot, filename) = savepng(mp.fig, filename)

showwidget(sp::MySubplots) = showwidget(sp.subplotWidget)
hidewidget(sp::MySubplots) = hidewidget(sp.subplotWidget)
widgetpos(sp::MySubplots) = widgetpos(sp.subplotWidget)
widgetsize(sp::MySubplots) = widgetsize(sp.subplotWidget)
movewidget(sp::MySubplots, x::Int, y::Int) = movewidget(sp.subplotWidget, x, y)
resizewidget(sp::MySubplots, width::Int, height::Int) = resizewidget(sp.subplotWidget, width, height)
move_resizewidget(sp::MySubplots, x::Int, y::Int, width::Int, height::Int) = move_resizewidget(sp.subplotWidget, x, y, width, height)
savepng(sp::MySubplots, filename) = savepng(sp.subplotWidget, filename)

showwidget(widget) = (widget[:showNormal](); widget[:raise_](); widget[:activateWindow](); nothing)
hidewidget(widget) = (widget[:hide](); nothing)
widgetpos(widget) = (point = widget[:pos](); (point[:x](), point[:y]))
widgetsize(widget) = (sz = widget[:pos](); (sz[:width](), sz[:height]))
movewidget(widget, x::Int, y::Int) = widget[:move](x,y)
resizewidget(widget, width::Int, height::Int) = widget[:resize](width, height)
move_resizewidget(widget, x::Int, y::Int, width::Int, height::Int) = (movewidget(widget, x, y); resizewidget(widget, width, height))
savepng(widget, filename) = QT.QPixmap()[:grabWidget](widget)[:save](filename, "PNG")

windowtitle(widget, title) = (widget[:setWindowTitle](title); nothing)
windowtitle(mp::MyPlot, title) = windowtitle(mp.fig, title)
windowtitle(sp::MySubplots, title) = windowtitle(sp.subplotWidget, title)

title(mp::MyPlot, title) = mp.fig[:setPlotTitle](title)
xlabel(mp::MyPlot, label) = mp.fig[:setXAxisTitle](label)
ylabel(mp::MyPlot, label) = mp.fig[:setYAxisTitle](label)
yrightlabel(mp::MyPlot, label) = mp.fig[:setYAxisTitleRight](label)


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

const DEFAULT_title = nothing
const DEFAULT_xlabel = nothing
const DEFAULT_ylabel = nothing
const DEFAULT_yrightlabel = nothing


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
function addline(mp::MyPlot, x, y, axis::Symbol, color::Symbol, label::String, width::Int, linetype::Symbol,
																	 linestyle::Symbol, marker::Symbol, markercolor::Symbol, markersize::Int, 
																	 heatmap_n::Int, heatmap_c::(Float64,Float64),
																	 tit, xlab, ylab, yrightlab)
	
	leftaxis = axis == :left
	isheatmap = linetype == :heatmap

	if leftaxis
		mp.numLeft += 1
		idx = mp.numLeft
	else
		mp.numRight += 1
		idx = mp.numRight
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
	plotitem = (isheatmap ? MyHeatMap(axis, label, idx, heatmap_n, mp) : MyLine(axis, label, idx, color, mp))

	setdata!(plotitem, x, y)
	push!(mp.lines, plotitem)

	# println("addline: $plotitem $color $label $width $linetype $linestyle $marker $markercolor $markersize $heatmap_n $heatmap_c")

	tit != nothing && title(mp, tit)
	xlab != nothing && xlabel(mp, xlab)
	ylab != nothing && ylabel(mp, ylab)
	yrightlab != nothing && yrightlabel(mp, yrightlab)

	# add it to the figure
	if isheatmap
		mp.fig[:addHeatMap](leftaxis, string(label), heatmap_c...)
	else
		args = map(string, (color, label, linetype, linestyle, marker, markercolor))
		mp.fig[:addLine](leftaxis, width, markersize, args...)
	end

	plotitem
end

getreglinecolor(line::MyLine) = line.color
getreglinecolor(hm::MyHeatMap) = :black

function addRegressionLine(line)
	x = [minimum(line.x), maximum(line.x)]
	reg = [line.x ones(length(line.x))] \ line.y
	y = reg[1] * x + reg[2]
	oplot(line.mp, x, y, label = split(line.label, " (")[1] * " REG", color = getreglinecolor(line), width = 3)
	nothing
end


oplot(mp::PlotOrSubPlot, y; kvs...) = oplot(mp; y = y, kvs...)
oplot(mp::PlotOrSubPlot, x, y; kvs...) = oplot(mp; x = x, y = y, kvs...)

# generic way to add to plot
function oplot(plt::PlotOrSubPlot; kvs...)
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
		windowtitle(plt, d[:windowtitle])
	end

	for c in 1:ycols
		x = X[:,(xcols==1 ? 1 : c)]
		mp = getMyPlot(plt, c)  # get the correct MyPlot... nop when plt is MyPlot, gets sp.plots[c] if MySubplot
		if isempty(x)
			continue
		end
		
		line = addline(mp, x, Y[:,c], [getarg(s,d,c) for s in (:axis, :color, :label, :width, :linetype, :linestyle, :marker, :markercolor, :markersize, :heatmap_n, :heatmap_c, :title, :xlabel, :ylabel, :yrightlabel)]...)
		# addline(plt, x, Y[:,c], getaxis(d,c), getcolor(d,c), getlabel(d,c), getkind(d,c), getsize(d,c))

		if haskey(d, :reg)
			addRegressionLine(line)
		end
	end

	update!(plt)
	plt
end


plot(y; kvs...) = plot(; y = y, kvs...)
plot(x, y; kvs...) = plot(; x = x, y = y, kvs...)

function plot(; kvs...)
	mp = MyPlot()
	oplot(mp; kvs...)
	showwidget(mp)
	moveWindowToCenterScreen(mp)
	mp
end


moveWindowToCenterScreen(mp) = movewidget(mp, 1920, 20) # TODO: remove??


end #module