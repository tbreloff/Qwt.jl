

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

			 Layout,
			 Splitter,
			 vbox,
			 hbox,
			 vsplitter,
			 hsplitter,

			 savepng,
			 animation,
			 saveframe,
			 makegif,

			 P2, # 2D point
			 P3, # 3D point
			 ORIGIN,
			 Scene,
			 SceneItem,
			 Ellipse,
			 Circle,
			 Rect,
			 Square,
			 Text,
			 Line,

			 currentScene,
			 currentScene!,
			 top,
			 bottom,
			 left,
			 right,
			 topleft,
			 bottomright,
			 background!,

			 makecolor,
			 makebrush,
			 makepen,
			 position3d,
			 position!,
			 # center,
			 # center!,
			 zvalue,
			 zvalue!,
			 rotation,
			 rotation!,
			 visible,
			 visible!,
			 parent,
			 parent!,
			 brush!,
			 pen!,
			 move!,
			 movex!,
			 movey!,
			 scale!,
			 scalex!,
			 scaley!,
			 rotate!,

			 ellipse!,
			 circle!,
			 rect!,
			 square!,
			 text!,
			 line!



print("Initializing Qwt... ")
using PyCall
unshift!(PyVector(pyimport("sys")["path"]), "")  # so you can load python files from the current directory
@pyimport PyQt4.Qt as QT
@pyimport BasicPlot as PLOT
@pyimport pythonwidgets as WIDGETS
@pyimport FancyPlot as FPLOT
# @pyimport ZoomableGraphicsView as ZOOM
pygui_start(:qt)
const QAPP = QT.QApplication([])
println("done.")


include("widgets.jl")
include("layout.jl")
include("plotitems.jl")
include("plot.jl")
include("subplot.jl")
include("animation.jl")
include("scene.jl")


end