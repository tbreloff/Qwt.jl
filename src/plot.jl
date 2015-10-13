
# NOTE: these can be standalone windows, or subplots within a Subplots window

abstract PlotWidget <: Widget

type Plot <: PlotWidget
  widget::PyObject  # BasicPlot
  lines::Vector{PlotItem}
  numLeft::Int
  numRight::Int
  autoscale_x::Bool
  autoscale_y::Bool
end

Plot() = Plot(PLOT.BasicPlot(), PlotItem[], 0, 0, true, true)

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

  plt.widget[:startUpdate](plt.autoscale_x, plt.autoscale_y)

  for l in plt.lines
    ca = get(plt.widget[isleft(l) ? "curvesAxis1" : "curvesAxis2"], l.idx-1)
    updateWidgetData(l, ca)
    # ca[:setData](l.x, l.y)
  end
  
  plt.widget[:finishUpdate]()
  # plt.widget[:replot]()

  nothing
end

function Base.empty!(plt::Plot)
  for l in plt.lines
    empty!(l)
  end
end

getplot(plt::Plot, c::Int) = plt
getline(plt::Plot, c::Int) = plt.lines[c]



title(plt::Plot, title::AbstractString) = plt.widget[:setPlotTitle](title)
xlabel(plt::Plot, label::AbstractString) = plt.widget[:setXAxisTitle](label)
ylabel(plt::Plot, label::AbstractString) = plt.widget[:setYAxisTitle](label)
yrightlabel(plt::Plot, label::AbstractString) = plt.widget[:setYAxisTitleRight](label)
hidelegend(plt::Plot) = plt.widget[:hideLegend]()
showlegend(plt::Plot) = plt.widget[:showLegend]()


# QwtScaleWidget *qwtsw = myqwtplot.axisWidget(QwtPlot::xBottom); 
#   QPalette palette = qwtsw->palette();  
#   palette.setColor( QPalette::WindowText, Qt::gray);  // for ticks
#   palette.setColor( QPalette::Text, Qt::gray);                  // for ticks' labels
#   qwtsw->setPalette( palette );

function updatePalette(plt::Plot, color, isbackground::Bool)
  qcolor = convertRGBToQColor(color)
  palette = plt.widget[:palette]()

  # note: 0 is for QPalette::WindowText, which is the foreground (axis borders, ticks),
  #       6 is for QPalette::Text
  #       10 is for QPalette::Window, which is background color (outside of axis canvas)
  enumvals = isbackground ? [10] : [0,6]
  for enumval in enumvals
    palette[:setColor](enumval, qcolor)
  end
  plt.widget[:setPalette](palette)
  plt.widget[:setAutoFillBackground](true)

  if isbackground
    plt.widget[:setCanvasBackground](qcolor)
  end
end


function foreground!(plt::Plot, color)
  updatePalette(plt, color, false)
end


function background!(plt::Plot, color)
  updatePalette(plt, color, true)
end

# ----------------------------------------------------------------

type CurrentPlot
  nullableplot::Nullable{Plot}
end
const CURRENT_PLOT = CurrentPlot(Nullable{Plot}())

function currentPlot()
  # create a new plot if it doesn't exist yet
  isnull(CURRENT_PLOT.nullableplot) && currentPlot!(Plot())
  get(CURRENT_PLOT.nullableplot)
end
currentPlot!(plot::Plot) = (CURRENT_PLOT.nullableplot = Nullable(plot))


# ----------------------------------------------------------------

# kvs is a list of (key,value) tuples, where key is a Symbol.
# valid keys: 
#   :x (can be vector, range, or matrix... if matrix, y must be matrix too, and nc must match)
#   :y (can be vector, range, or matrix... if matrix, series must go down the columns)

# you can specify any of the following optional arguments
# Note they are all Symbol's (except label, which is a string)
#   :axis, :color, :label, :linetype, :linestyle, :marker, :markercolor

# you can also specify lists of these values, 1 per series, by adding an s to the end of the symbol: 
#   :axiss, :colors, etc


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
const DEFAULT_fillto = nothing
const DEFAULT_fillcolor = :auto

const DEFAULT_title = ""
const DEFAULT_xlabel = ""
const DEFAULT_ylabel = ""
const DEFAULT_yrightlabel = ""
const DEFAULT_legend = true


makematrix(i::Int) = zeros(Float64, 0, i)
makematrix{T<:Number}(z::Matrix{T}) = convert(Matrix{Float64}, z)
makematrix{T<:Number}(z::Union{StepRange{T,T},UnitRange{T},FloatRange{T},Vector{T}}) = convert(Matrix{Float64}, reshape(z, length(z), 1))
buildX(Y::Matrix{Float64}) = makematrix(1:size(Y,1))

makeplural(s::Symbol) = Symbol(string(s,"s"))
makedefault(s::Symbol) = Symbol(string("DEFAULT_",s))

convertRGBToQColor(rgb::RGB) = QT.QColor(Float64[f(rgb)*255 for f in (red,green,blue)]...)
convertRGBToQColor(color::Colorant) = QT.QColor(Float64[f(color)*255 for f in (red,green,blue,alpha)]...)

"duplicate a single value, or pass the 2-tuple through"
maketuple(x::Real) = (x,x)
maketuple{T,S}(x::Tuple{T,S}) = x

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
function addline(plt::Plot, x, y, color, markercolor, fillcolor,
                                   axis::Symbol, label::AbstractString, width::Int, linetype::Symbol,
                                   linestyle::Symbol, marker::Symbol, markersize::Int, 
                                   heatmap_n, heatmap_c::Tuple{Float64,Float64},
                                   tit::AbstractString, xlab::AbstractString, ylab::AbstractString, yrightlab::AbstractString, fillto)
  
  leftaxis = axis == :left
  isheatmap = linetype == :heatmap

  if leftaxis
    plt.numLeft += 1
    idx = plt.numLeft
  else
    plt.numRight += 1
    idx = plt.numRight
  end

  color = (isa(color, Symbol) ? (color == :auto ? autocolor(idx) : string(color)) : color)
  markercolor = (isa(markercolor, Symbol) ? (markercolor == :auto ? autocolor(idx) : string(markercolor)) : markercolor)
  fillcolor = (isa(fillcolor, Symbol) ? (fillcolor == :auto ? autocolor(idx) : string(fillcolor)) : fillcolor)
  label = string(label == "AUTO" ? "y_$idx" : label, leftaxis ? "" : " (R)")

  # println(color)

  # check our inputs
  # @assert color in COLORS
  # @assert width > 0
  # @assert markersize > 0
  @assert linetype in LINE_TYPES
  @assert linestyle in LINE_STYLES
  @assert marker in LINE_MARKERS
  # @assert markercolor in COLORS
  # @assert heatmap_n > 0
  @assert heatmap_c[1] >= 0.0 && heatmap_c[2] >= heatmap_c[1]

  heatmap_nx, heatmap_ny = maketuple(heatmap_n)

  # create a new plotitem
  plotitem = (isheatmap ? HeatMap(axis, label, idx, heatmap_nx, heatmap_ny, plt) : Series(axis, label, idx, color, plt))

  setdata(plotitem, x, y)
  push!(plt.lines, plotitem)

  tit != "" && title(plt, tit)
  xlab != "" && xlabel(plt, xlab)
  ylab != "" && ylabel(plt, ylab)
  yrightlab != "" && yrightlabel(plt, yrightlab)


  # add it to the figure
  if isheatmap
    plt.widget[:addHeatMap](leftaxis, string(label), heatmap_c...)
  else
    args = map(string, (label, linetype, linestyle, marker))
    plt.widget[:addLine](leftaxis, width, markersize, color, args..., markercolor, fillto, fillcolor)
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
oplot(args...; kwargs...) = oplot(currentPlot(), args...; kwargs...)

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

  # add the lines
  for c in 1:ycols
    x = X[:,(xcols==1 ? 1 : c)]
    plt = getplot(plotwidget, c)  # get the correct Plot... nop when plotwidget is Plot, gets sp.plots[c] if MySubplot
    # if isempty(x)
    #   continue
    # end

    # convert Colorant to QColor
    color = getarg(:color, d, c)
    if isa(color, Colors.Colorant)
      color = convertRGBToQColor(color)
    end
    markercolor = getarg(:markercolor, d, c)
    if isa(markercolor, Colors.Colorant)
      markercolor = convertRGBToQColor(markercolor)
    end
    fillcolor = getarg(:fillcolor, d, c)
    if isa(fillcolor, Colors.Colorant)
      fillcolor = convertRGBToQColor(fillcolor)
    end
    
    line = addline(plt, x, Y[:,c], color, markercolor, fillcolor, [getarg(s,d,c) for s in (:axis, :label, :width, :linetype, :linestyle, :marker, :markersize, :heatmap_n, :heatmap_c, :title, :xlabel, :ylabel, :yrightlabel, :fillto)]...)

    if haskey(d, :reg) && d[:reg]
      addRegressionLine(line)
    end
  end

  updateWindow(plotwidget, d)
  plotwidget
end

function updateWindow(plotwidget::PlotWidget, d::Dict)
  if haskey(d, :size)
    resizewidget(plotwidget, d[:size]...)
  end
  if haskey(d, :windowtitle)
    windowtitle(plotwidget, d[:windowtitle])
  end

  if haskey(d, :screen)
    moveToScreen(plotwidget, d[:screen])
  elseif haskey(d, :pos)
    movewidget(plotwidget, d[:pos]...)
  end

  if haskey(d, :legend)
    d[:legend] ? showlegend(plotwidget) : hidelegend(plotwidget)
  end

  if haskey(d, :background_color)
    background!(plotwidget, d[:background_color])
  end
  if haskey(d, :foreground_color)
    foreground!(plotwidget, d[:foreground_color])
  end

  refresh(plotwidget)

  if haskey(d, :show) && d[:show]
    showwidget(plotwidget)
  end
end


plot(y::AbstractArray; kvs...) = plot(; y = y, kvs...)
plot(x::AbstractArray, y::AbstractArray; kvs...) = plot(; x = x, y = y, kvs...)
plot(f::Function, x::AbstractArray; kvs...) = plot(; x = x, y = map(f, x), kvs...)

# plot!(plt::PlotWidget, )

function plot(; kvs...)
  
  plt = Plot()
  currentPlot!(plt)
  resizewidget(plt, 800, 600)
  moveToLastScreen(plt)  # partial hack so it goes to my center monitor... sorry

  # show the plot (unless show=false)
  if !((:show, false) in kvs)
    push!(kvs, (:show, true))
  end

  oplot(plt; kvs...)
  plt
end



scatter(args...; kwargs...) = plot(args...; kwargs..., linetype=:dots)
heatmap(args...; kwargs...) = plot(args...; kwargs..., linetype=:heatmap)
