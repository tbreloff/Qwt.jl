

require("PyCall")


module Qwt


export plot,
			 oplot,
			 subplot,
			 scatter,
			 heatmap,

			 setdata,
			 refresh,
			 title,
			 xlabel,
			 ylabel,
			 yrightlabel,
			 windowtitle,

			 savepng,
			 animation,
			 saveframe,
			 makegif

# This is a wrapper around python, which is in turn a wrapper around Qwt5's plotting

# ZOOMING
# click and drag with the left mouse button to select a rectangle to zoom into
# to undo 1 zoom, hold ALT and click the right mouse button
# to redo 1 zoom, hold SHIFT and click the right mouse button
# to reset the zoom stack, click the middle mouse button

# PANNING
# click and drag with the right mouse button


# QT initialization
print("Initializing Qwt... ")
using PyCall
@pyimport PyQt4.Qt as QT
@pyimport BasicPlot as PLOT
pygui_start(:qt)
const QAPP = QT.QApplication([])
println("done.")




include("widgets.jl")
include("plotitems.jl")
include("plot.jl")
include("subplot.jl")
include("animation.jl")


end