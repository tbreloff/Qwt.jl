
# a Widget is expected to have a field "widget::PyObject" which is a QWidget
abstract Widget

roundint(x::AbstractFloat) = round(Int, x)


# methods for the python widget
showwidget(w::PyObject) = (w[:showNormal](); w[:raise_](); w[:activateWindow](); nothing)
hidewidget(w::PyObject) = (w[:hide](); nothing)
widgetpos(w::PyObject) = (point = w[:pos](); (point[:x](), point[:y]))
widgetsize(w::PyObject) = (sz = w[:size](); (sz[:width](), sz[:height]))
movewidget(w::PyObject, x::Int, y::Int) = w[:move](x,y)
movewidget(w::PyObject, pos::P2) = movewidget(w, map(roundint,pos)...)
resizewidget(w::PyObject, width::Int, height::Int) = w[:resize](width, height)
resizewidget(w::PyObject, sz::P2) = resizewidget(w, map(roundint,sz)...)
move_resizewidget(w::PyObject, x::Int, y::Int, width::Int, height::Int) = (movewidget(w, x, y); resizewidget(w, width, height))
move_resizewidget(w::PyObject, pos::P2, sz::P2) = (movewidget(w, pos); resizewidget(w, sz))
savepng(w::PyObject, filename::AbstractString) = QT.QPixmap()[:grabWidget](w)[:save](filename, "PNG")
windowtitle(w::PyObject, title::AbstractString) = (w[:setWindowTitle](title); nothing)
Base.close(w::PyObject) = hidewidget(w)  # TODO: clean up python objects properly
moveToScreen(w::PyObject, screenNum::Int = 1) = movewidget(w, screenPosition(screenNum))
moveToLastScreen(w::PyObject) = moveToScreen(w, screenCount())


# methods for the Julia widget (generally just pass to the python version)
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
moveToScreen(w::Widget, screenNum::Int = 1) = moveToScreen(w.widget, screenNum)
moveToLastScreen(w::Widget) = moveToLastScreen(w.widget)


# methods for desktop info
desktop() = QAPP[:desktop]()
screenCount() = desktop()[:screenCount]()
screenGeometry(screenNum::Int = 1) = desktop()[:screenGeometry](screenNum)
screenPosition(screenNum::Int = 1) = position(screenGeometry(screenNum))
screenSize(screenNum::Int = 1) = size(screenGeometry(screenNum))

