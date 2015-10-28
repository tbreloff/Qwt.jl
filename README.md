# Qwt.jl

#### Author: Thomas Breloff (@tbreloff)

**NOTE**: I recommend using [Plots.jl](https://github.com/tbreloff/Plots.jl.git) as the plotting interface for Qwt.

Plotting using PyQt/PyQwt and a clean interface for 2D scenes using QCanvas.  Add to PyQt GUIs and compose many widgets
together for complex visualizations.

## Install

- Install python and PyQt4
- Install PyQwt.  If you can't find a bundled package through brew, yum, apt-get, etc:
  - Download tar from: http://sourceforge.net/projects/pyqwt/files/pyqwt5/
  - cd <download_location>
  - tar -zxvf PyQwt-5.2.0.tar.gz
  - cd PyQwt-5.2.1/configure
  - python configure.py -Q ../qwt-5.2
  - make
  - sudo make install

__Tip__: On OS X, `brew install pyqt` and `brew install pyqwt` might be all you need.


## Zooming
- Click and drag with the left mouse button to select a rectangle to zoom into
- To undo 1 zoom, hold ALT and click the right mouse button
- To redo 1 zoom, hold SHIFT and click the right mouse button
- To reset the zoom stack, click the middle mouse button

## Panning
- Click and drag with the right mouse button

## Other

- Click on legend labels to hide/show individual series


## Examples:

```
using Qwt

# simple 2D line plot
plot(1:10)

# these are equivalent
x = randn(100) * 5
y = sin(x)
plot(x, y, linetype=:dots)
scatter(x, y)

# create a heatmap (and optionally fine-tune coloring)
# heatmap_n is the number of bins on each axis
# heatmap_c is the cutoff points of the color range
heatmap(randn(10000), randn(10000); heatmap_n = 20, heatmap_c = (0.05, 0.3))

# pass in vectors or matrices, and it should slice it up properly
Y = rand(100,9)  												# matrix with series in columns
subplot(Y) 															# creates a 3x3 grid of subplots, (one per column)
subplot(rand(100), Y, linetype=:dots)		# same, but has shared x-data
plot(Y)																	# plots 5 lines on the same axis (one per column)

# use both axes
plot(Y[:,1:2], axiss=[:left, :right], colors=[:blue, :green])

# you could also add it after the fact
y1, y2 = Y[:,1], Y[:,2]
plt = plot(y1, color = :blue)
oplot(plt, y2, axis = :right, color = :green)

# there are lots of things to adjust
plot(y1, axis = :right,
				 color = :red,
				 label = "my line",
				 width = 5,
				 linetype = :step,
				 linestyle = :dashdot,
				 marker = :ellipse,
				 markercolor = :cyan,
				 markersize = 20,
				 title = "my title",
				 xlabel = "my x label",
				 ylabel = "my y label"
				 yrightlabel = "my right axis y label",
				 reg = true  # adds a regression line for each series
				 ) 

# and anything can be pluralized by adding an "s" to the end and passing a vector
plot(Y[:,1:2], colors = [:red, :blue])

# add to a plot in real time
plt = plot([0],[0])
for x in 0:0.1:100
	push!(plt, 1, x, sin(x))
	refresh(plt)
	sleep(0.01)
end


# save a png
savepng(plt, "/tmp/png/plot0001.png")


# save an animated gif (requires ffmpeg... saves to $dir/out.gif)
empty!(plt)
a = animation(plt, "/tmp/png")
for x in 0:0.1:5
	push!(plt, 1, x, sin(x))
	refresh(plt)
	saveframe(a)
end
makegif(a)

```
