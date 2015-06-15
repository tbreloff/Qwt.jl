
# a Widget is expected to have a field "widget::PyObject" which is a QWidget
abstract Widget

roundint(x::FloatingPoint) = round(Int, x)

showwidget(w::PyObject) = (w[:showNormal](); w[:raise_](); w[:activateWindow](); nothing)
hidewidget(w::PyObject) = (w[:hide](); nothing)
widgetpos(w::PyObject) = (point = w[:pos](); (point[:x](), point[:y]))
widgetsize(w::PyObject) = (sz = w[:pos](); (sz[:width](), sz[:height]))
movewidget(w::PyObject, x::Int, y::Int) = w[:move](x,y)
movewidget(w::PyObject, pos::P2) = movewidget(w, map(roundint,pos)...)
resizewidget(w::PyObject, width::Int, height::Int) = w[:resize](width, height)
resizewidget(w::PyObject, sz::P2) = resizewidget(w, map(roundint,sz)...)
move_resizewidget(w::PyObject, x::Int, y::Int, width::Int, height::Int) = (movewidget(w, x, y); resizewidget(w, width, height))
move_resizewidget(w::PyObject, pos::P2, sz::P2) = (movewidget(w, pos); resizewidget(w, sz))
savepng(w::PyObject, filename::String) = QT.QPixmap()[:grabWidget](w)[:save](filename, "PNG")
windowtitle(w::PyObject, title::String) = (w[:setWindowTitle](title); nothing)
Base.close(w::PyObject) = hidewidget(w)  # TODO: clean up python objects properly



showwidget(w::Widget) = showwidget(w.widget)
hidewidget(w::Widget) = hidewidget(w.widget)
widgetpos(w::Widget) = widgetpos(w.widget)
widgetsize(w::Widget) = widgetsize(w.widget)
movewidget(w::Widget, args...) = movewidget(w.widget, args...)
resizewidget(w::Widget, args...) = resizewidget(w.widget, args...)
move_resizewidget(w::Widget, args...) = move_resizewidget(w.widget, args...)
savepng(w::Widget, args...) = savepng(w.widget, args...)
windowtitle(w::Widget, args...) = windowtitle(w.widget, args...)
Base.close(w::Widget) = close(w.widget)

moveWindowToCenterScreen(w::Widget) = movewidget(w::Widget, 1920, 20) # TODO: remove? calculate correct coords?
