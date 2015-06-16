

type Subplots <: PlotWidget
  widget::PyObject
  plots::Vector{Plot}
  n::Int
  nrowsOverride::Int
  ncolsOverride::Int
  nrows::Int
  ncols::Int

  Subplots() = new(PLOT.SubplotWidget(), [], 0, 0, 0)
end

function updateGrid(sp::Subplots)
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

function getplot(sp::Subplots, c::Int)
  while c > length(sp.plots)
    push!(sp.plots, Plot())
    sp.n += 1
    updateGrid(sp)
  end
  sp.plots[c]
end


function refresh(sp::Subplots)
  for plt in sp.plots
    refresh(plt)
  end
  widgets = reshape([[plt.widget for plt in sp.plots] ; fill(nothing, sp.nrows*sp.ncols - sp.n)], sp.ncols, sp.nrows)'
  sp.widget[:addFigures](widgets)
  nothing
end


subplot(y; kvs...) = subplot(; y = y, kvs...)
subplot(x, y; kvs...) = subplot(; x = x, y = y, kvs...)

function subplot(; kvs...)
  sp = Subplots()
  resizewidget(sp, 800, 600)
  moveToLastScreen(sp)
  
  d = Dict(kvs)
  sp.nrowsOverride = get(d, :nrows, 0)
  sp.ncolsOverride = get(d, :ncols, 0)

  if !((:show, false) in kvs)
    push!(kvs, (:show, true))
  end

  oplot(sp; kvs...)
  sp
end
