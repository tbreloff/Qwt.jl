
# a Widget is expected to have a field "widget::PyObject" which is a QWidget
abstract Widget

showwidget(widget::PyObject) = (widget[:showNormal](); widget[:raise_](); widget[:activateWindow](); nothing)
hidewidget(widget::PyObject) = (widget[:hide](); nothing)
widgetpos(widget::PyObject) = (point = widget[:pos](); (point[:x](), point[:y]))
widgetsize(widget::PyObject) = (sz = widget[:pos](); (sz[:width](), sz[:height]))
movewidget(widget::PyObject, x::Int, y::Int) = widget[:move](x,y)
resizewidget(widget::PyObject, width::Int, height::Int) = widget[:resize](width, height)
move_resizewidget(widget::PyObject, x::Int, y::Int, width::Int, height::Int) = (movewidget(widget, x, y); resizewidget(widget, width, height))
savepng(widget::PyObject, filename::String) = QT.QPixmap()[:grabWidget](widget)[:save](filename, "PNG")
windowtitle(widget::PyObject, title::String) = (widget[:setWindowTitle](title); nothing)
moveWindowToCenterScreen(mp) = movewidget(mp, 1920, 20) # TODO: remove??



showwidget(w::Widget) = showwidget(w.widget)
hidewidget(w::Widget) = hidewidget(w.widget)
widgetpos(w::Widget) = widgetpos(w.widget)
widgetsize(w::Widget) = widgetsize(w.widget)
movewidget(w::Widget, x::Int, y::Int) = movewidget(w.widget, x, y)
resizewidget(w::Widget, width::Int, height::Int) = resizewidget(w.widget, width, height)
move_resizewidget(w::Widget, x::Int, y::Int, width::Int, height::Int) = move_resizewidget(w.widget, x, y, width, height)