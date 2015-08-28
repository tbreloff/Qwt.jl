

module Qwt

# VERSION >= v"0.4.0-dev+6521" && __precompile__()
__precompile__(false)


export 
  plot,
  oplot,
  subplot,
  scatter,
  heatmap,

  currentPlot,
  currentPlot!,

  getline,
  setdata,
  addRegressionLine,
  refresh,
  title,
  xlabel,
  ylabel,
  yrightlabel,
  windowtitle,
  hidelegend,
  showlegend,

  Widget,
  PlotWidget,
  Plot,

  hidewidget,
  showwidget,
  widgetpos,
  widgetsize,
  movewidget,
  resizewidget,
  move_resizewidget,
  screenCount,
  screenPosition,
  screenSize,
  moveToScreen,
  moveToLastScreen,

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
  Point,
  ORIGIN,
  Scene,
  SceneItem,
  Ellipse,
  Circle,
  Rect,
  Square,
  SceneText,
  Line,

  currentScene,
  currentScene!,
  defaultBrush,
  defaultBrush!,
  defaultPen,
  defaultPen!,
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
  settext,

  ellipse!,
  circle!,
  rect!,
  square!,
  text!,
  line!

# ------------------------------------------------------
# Setup Qt
# ------------------------------------------------------

using PyCall

# function __init__()
print("Initializing Qwt... ")
# global QT, PLOT, WIDGETS, QAPP
@pyimport PyQt4.Qt as QT
@pyimport BasicPlot as PLOT
@pyimport pythonwidgets as WIDGETS
# QT = QT2
# PLOT = PLOT2
# WIDGETS = WIDGETS2
# unshift!(PyVector(pyimport("sys")["path"]), "")  # so you can load python files from the current directory
# @pyimport FancyPlot as FPLOT
pygui_start(:qt_pyqt4)
const QAPP = QT.QApplication([])
println("done.")
# end
# ------------------------------------------------------


using ImmutableArrays

typealias P2 Vector2{Float64}
typealias P3 Vector3{Float64}
typealias Point Union(P2,P3)

const ORIGIN = P3(0,0,0)

P2(p::P3) = P2(p[1], p[2])
P3(p::P2, z::Real) = P3(p[1], p[2], z)
P3(p::P2) = P3(p, 0.0)



include("widgets.jl")
include("layout.jl")
include("plotitems.jl")
include("plot.jl")
include("subplot.jl")
include("animation.jl")
include("scene.jl")


end