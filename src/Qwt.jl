

require("PyCall")


module Qwt


export plot,
			 oplot,
			 subplot,
			 scatter,
			 heatmap,

			 getline,
			 setdata,
			 addRegressionLine,
			 refresh,
			 title,
			 xlabel,
			 ylabel,
			 yrightlabel,
			 windowtitle,

			 hidewidget,
			 showwidget,
			 widgetpos,
			 widgetsize,
			 movewidget,
			 resizewidget,
			 move_resizewidget,

			 savepng,
			 animation,
			 saveframe,
			 makegif


print("Initializing Qwt... ")
using PyCall
unshift!(PyVector(pyimport("sys")["path"]), "")
@pyimport PyQt4.Qt as QT
@pyimport BasicPlot as PLOT
@pyimport pythonwidgets as WIDGETS
@pyimport FancyPlot as FPLOT
# @pyimport ZoomableGraphicsView as ZOOM
pygui_start(:qt)
const QAPP = QT.QApplication([])
println("done.")




include("widgets.jl")
include("plotitems.jl")
include("plot.jl")
include("subplot.jl")
include("animation.jl")


end