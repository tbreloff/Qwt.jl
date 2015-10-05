
abstract PlotItem

########################################################################################

type Series <: PlotItem
  axis::Symbol
  label::AbstractString
  idx::Int
  color
  plt
  x::Vector{Float64}
  y::Vector{Float64}

  function Series(axis::Symbol, label::AbstractString, idx::Int, color, plt)
    @assert axis in (:left, :right)
    new(axis, label, idx, color, plt, zeros(0), zeros(0))
  end
end

Base.string(line::Series) = "Series{axis=$(line.axis) label=$(line.label) idx=$(line.idx) npoints=$(length(line.x))}"
Base.print(io::IO, line::Series) = print(io, string(line))
Base.show(io::IO, line::Series) = print(io, string(line))

isleft(line::Series) = line.axis == :left
isright(line::Series) = line.axis == :right


function Base.push!(line::Series, x::Float64, y::Float64)
  push!(line.x, x)
  push!(line.y, y)
  nothing
end

function Base.push!(line::Series, x::Number, y::Number)
  push!(line, convert(Float64, x), convert(Float64, y))
end

function setdata(line::Series, x::Vector{Float64}, y::Vector{Float64})
  @assert length(x) == length(y)
  line.x = x
  line.y = y
end

function Base.empty!(line::Series)
  setdata(line, zeros(0), zeros(0))
end

updateWidgetData(line::Series, pyobj::PyObject) = pyobj[:setData](line.x, line.y)

getreglinecolor(line::Series) = line.color


########################################################################################

type HeatMap <: PlotItem
  axis::Symbol
  label::AbstractString
  idx::Int
  x::Vector{Float64}
  y::Vector{Float64}
  recalcOnUpdate::Bool
  nx::Int
  ny::Int
  plt

  function HeatMap(axis::Symbol, label::AbstractString, idx::Int, nx::Int, ny::Int, plt)
    @assert axis in (:left, :right)
    new(axis, label, idx, zeros(0), zeros(0), true, nx, ny, plt)
  end
end

Base.string(heatmap::HeatMap) = "HeatMap{axis=$(heatmap.axis) label=$(heatmap.label) idx=$(heatmap.idx) npoints=$(length(heatmap.x))}"
Base.print(io::IO, heatmap::HeatMap) = print(io, string(heatmap))
Base.show(io::IO, heatmap::HeatMap) = print(io, string(heatmap))

isleft(heatmap::HeatMap) = heatmap.axis == :left
isright(heatmap::HeatMap) = heatmap.axis == :right


function Base.push!(heatmap::HeatMap, x::Float64, y::Float64)
  push!(heatmap.x, x)
  push!(heatmap.y, y)
  nothing
end

function Base.push!(heatmap::HeatMap, x::Number, y::Number)
  push!(heatmap, convert(Float64, x), convert(Float64, y))
end

function setdata(heatmap::HeatMap, x::Vector{Float64}, y::Vector{Float64})
  @assert length(x) == length(y)
  heatmap.x = x
  heatmap.y = y
end

function updateWidgetData(heatmap::HeatMap, pyobj::PyObject)
  if heatmap.recalcOnUpdate
    heatMapData = PLOT.HeatMapData(heatmap.x, heatmap.y, heatmap.nx, heatmap.ny)
    pyobj[:setData](heatMapData)
    recalcOnUpdate = false
  end
end

getreglinecolor(hm::HeatMap) = :black
