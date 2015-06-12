

type Subplots <: PlotWidget
	widget::PyObject
	plots::Vector{Plot}
	n::Int
	nrowsOverride::Int
	ncolsOverride::Int
	nrows::Int
	ncols::Int

	function Subplots()
		widget = PLOT.SubplotWidget()
		widget[:resize](800,600)
		new(widget, [], 0, 0, 0)
	end
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
	
	d = Dict(kvs)
	sp.nrowsOverride = get(d, :nrows, 0)
	sp.ncolsOverride = get(d, :ncols, 0)

	oplot(sp; kvs...)
	sp.widget[:show]()
	moveWindowToCenterScreen(sp)
	sp
end



# showwidget(sp::Subplots) = showwidget(sp.widget)
# hidewidget(sp::Subplots) = hidewidget(sp.widget)
# widgetpos(sp::Subplots) = widgetpos(sp.widget)
# widgetsize(sp::Subplots) = widgetsize(sp.widget)
# movewidget(sp::Subplots, x::Int, y::Int) = movewidget(sp.widget, x, y)
# resizewidget(sp::Subplots, width::Int, height::Int) = resizewidget(sp.widget, width, height)
# move_resizewidget(sp::Subplots, x::Int, y::Int, width::Int, height::Int) = move_resizewidget(sp.widget, x, y, width, height)
savepng(sp::Subplots, filename::String) = savepng(sp.widget, filename)

windowtitle(sp::Subplots, title::String) = windowtitle(sp.widget, title)
