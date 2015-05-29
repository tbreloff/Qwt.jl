# Qwt.jl
Plot using Qwt (currently through PyQwt)

# ZOOMING
click and drag with the left mouse button to select a rectangle to zoom into
to undo 1 zoom, hold ALT and click the right mouse button
to redo 1 zoom, hold SHIFT and click the right mouse button
to reset the zoom stack, click the middle mouse button

# PANNING
click and drag with the right mouse button

# Examples:

'''
# simple 2D line plot
plot(1:10)

# these are equivalent
x = randn(100) * 5
y = sin(x)
plot(x, y, linetype=:dots)
scatter(x, y)

# create a heatmap (and fine-tune coloring)
heatmap(randn(10000),randn(10000))

subplot(rand(100,9))
'''
