

abstract SceneItem

# -----------------------------------------------------------------------

immutable Scene <: Widget
  widget::PyObject # qt view
  scene::PyObject # qt scene
  items::Vector{SceneItem}
end

# set up the scene
function Scene(pos::P2 = P2(2000,0), sz::P2 = P2(1000,1000); show=true)

  scene = QT.QGraphicsScene()
  widget = QT.QGraphicsView(scene)

  # adjust position and window coordinates
  screenx, screeny = pos
  w, h = sz
  widget[:setGeometry](screenx, screeny, w+1, h+1)

  # w, h = size(widget[:contentsRect]()[:size]())
  # scene[:setSceneRect](-w/2, -h/2, w, h)

  if show
    showwidget(widget)
  end

  s = Scene(widget, scene, SceneItem[])
  recenterScene(s)
  currentScene!(s)
  s
end

# rescale w,h to contents size
function recenterScene(scene::Scene)
  w, h = size(scene.widget[:contentsRect]()[:size]())
  scene.scene[:setSceneRect](-w/2, -h/2, w, h)
  nothing
end


function Base.push!(scene::Scene, item::SceneItem)
  scene.scene[:addItem](item.o)
  push!(scene.items, item)
  item
end

function Base.empty!(scene::Scene)
  empty!(scene.items)
  scene.scene[:clear]()
end

# # coordinates of widget on screen
# showwidget(scene::Scene) = showwidget(scene.widget)
# hidewidget(scene::Scene) = hidewidget(scene.widget)
# widgetpos(scene::Scene) = widgetpos(scene.widget)
# widgetsize(scene::Scene) = widgetsize(scene.widget)
# movewidget(scene::Scene, x::Int, y::Int) = movewidget(scene.widget, x, y)
# resizewidget(scene::Scene, width::Int, height::Int) = resizewidget(scene.widget, width, height)
# move_resizewidget(scene::Scene, x::Int, y::Int, width::Int, height::Int) = move_resizewidget(scene.widget, x, y, width, height)

# coordinates within scene
rect(scene::Scene) = scene.scene[:sceneRect]()
Base.size(scene::Scene) = size(rect(scene)[:size]())
top(scene::Scene) = rect(scene)[:top]()
bottom(scene::Scene) = rect(scene)[:bottom]()
left(scene::Scene) = rect(scene)[:left]()
right(scene::Scene) = rect(scene)[:right]()
topleft(scene::Scene) = position(rect(scene)[:topLeft]())
bottomright(scene::Scene) = position(rect(scene)[:bottomRight]())

background!(scene::Scene, args...) = (scene.scene[:setBackgroundBrush](makebrush(args...)); scene)
background!(args...) = background!(currentScene(), args...)

# -----------------------------------------------------------------------

convertToRGBInt(x::Real) = max(0, min(round(Int, x * 255.0), 255))

makecolor(color::Symbol) = QT.QColor(string(color))
makecolor(color::AbstractString) = QT.QColor(color)
makecolor(args...) = QT.QColor(map(convertToRGBInt, args)...)  # args: r, g, b [, a]

makebrush(args...) = QT.QBrush(makecolor(args...))
makepen(width::Real, args...) = width == 0 ? QT.QPen(0) : QT.QPen(makecolor(args...), float(width))

# -----------------------------------------------------------------------

type CurrentScene
  nullablescene::Nullable{Scene}
  defaultBrush::PyObject
  defaultPen::PyObject
end
# const CURRENT_SCENE = CurrentScene(Nullable{Scene}(), makebrush(:black), makepen(2, :black))

function currentScene()
  # create a new scene if it doesn't exist yet
  isnull(CURRENT_SCENE.nullablescene) && currentScene!(Scene())
  get(CURRENT_SCENE.nullablescene)
end
currentScene!(scene::Scene) = (CURRENT_SCENE.nullablescene = Nullable(scene))

defaultBrush() = CURRENT_SCENE.defaultBrush
defaultPen() = CURRENT_SCENE.defaultPen
defaultBrush!(args...) = (CURRENT_SCENE.defaultBrush = makebrush(args...); nothing)
defaultPen!(args...) = (CURRENT_SCENE.defaultPen = makepen(args...); nothing)


# -----------------------------------------------------------------------

# note: position is the center!!

Base.size(o::PyObject) = P2(o[:width](), o[:height]())  # assume we're passed in a QSize
Base.position(o::PyObject) = P2(o[:x](), o[:y]())  # assume we're passed in a QPoint

P2(item::SceneItem) = position(item)
P3(item::SceneItem) = position3d(item)
Base.size(item::SceneItem) = size(item.o[:size]())
Base.position(item::SceneItem) = position(item.o[:pos]())
position3d(item::SceneItem) = P3(position(item)..., zvalue(item))
position!(item::SceneItem, p::P2) = (item.o[:setPos](p...); item)
position!(item::SceneItem, p::P3) = (position!(item, P2(p)); zvalue!(item, p[3]); item)
zvalue(item::SceneItem) = item.o[:zValue]()
zvalue!(item::SceneItem, z::Real) = (item.o[:setZValue](float(z)); item)
rotation(item::SceneItem) = item.o[:rotation]()
rotation!(item::SceneItem, deg::Real) = (item.o[:setRotation](float(deg)); item)
visible(item::SceneItem) = item.o[:isVisible]()
visible!(item::SceneItem, b::Bool) = (item.o[:setVisible](b); item)
Base.parent(item::SceneItem) = item.o[:parentItem]()
parent!(item::SceneItem, parent::SceneItem) = (item.o[:setParentItem](parent.o); item)

brush!(item::SceneItem, args...) = brush!(item, makebrush(args...))
brush!(item::SceneItem, brush::PyObject) = (item.o[:setBrush](brush); item)
pen!(item::SceneItem, width::Real, args...) = pen!(item, makepen(float(width), args...))
pen!(item::SceneItem, pen::PyObject) = (item.o[:setPen](pen); item)

# these are relative changes
move!(item::SceneItem, p::P2) = (item.o[:moveBy](p...); item)
movex!(item::SceneItem, x::Real) = move!(item, P2(x, 0))
movey!(item::SceneItem, y::Real) = move!(item, P2(0, y))
Base.scale!(item::SceneItem, p::P2) = (item.o[:scale](p...); item)
Base.scale!(item::SceneItem, s::Real) = scale!(item, P2(s, s))
scalex!(item::SceneItem, x::Real) = scale!(item, P2(x, 0))
scaley!(item::SceneItem, y::Real) = scale!(item, P2(y, 0))
rotate!(item::SceneItem, deg::Real) = rotation!(item, deg + rotation(item))

# -----------------------------------------------------------------------

immutable Ellipse <: SceneItem; o::PyObject; end
function Ellipse(radius::P2, pos::Point = ORIGIN)
  rx, ry = radius
  item = Ellipse(QT.QGraphicsEllipseItem(-rx, -ry, rx*2.0, ry*2.0))
  position!(item, pos)
  brush!(item, defaultBrush())
  pen!(item, defaultPen())
  item
end
Circle(radius::Real, center::Point = ORIGIN) = Ellipse(P2(radius, radius), center)

ellipse!(scene::Scene, args...) = push!(scene, Ellipse(args...))
ellipse!(args...) = ellipse!(currentScene(), args...)
circle!(scene::Scene, args...) = push!(scene, Circle(args...))
circle!(args...) = circle!(currentScene(), args...)

# -----------------------------------------------------------------------

immutable Rect <: SceneItem; o::PyObject; end
function Rect(sz::P2, pos::Point = ORIGIN)
  w, h = sz
  item = Rect(QT.QGraphicsRectItem(-w/2, -h/2, w, h))
  position!(item, pos)
  brush!(item, defaultBrush())
  pen!(item, defaultPen())
  item
end
Square(w::Real, pos::Point = ORIGIN) = Rect(P2(w, w), pos)

rect!(scene::Scene, args...) = push!(scene, Rect(args...))
rect!(args...) = rect!(currentScene(), args...)
square!(scene::Scene, args...) = push!(scene, Square(args...))
square!(args...) = square!(currentScene(), args...)

# -----------------------------------------------------------------------

immutable SceneText <: SceneItem; o::PyObject; end
function SceneText(s::AbstractString, pos::Point = ORIGIN)
  item = SceneText(QT.QGraphicsSimpleTextItem(s))
  position!(item, pos)
  # brush!(item, defaultBrush())
  # pen!(item, defaultPen())
  item
end

text!(scene::Scene, args...) = push!(scene, SceneText(args...))
text!(args...) = text!(currentScene(), args...)

Base.size(item::SceneText) = size(item.o[:boundingRect]()[:size]())
Base.position(item::SceneText) = position(item.o[:boundingRect]()[:pos]()) + size(item)/2
function position!(item::SceneText, p::P2)
  p = p - size(item)/2
  item.o[:setPos](p...)
  item
end
settext(item::SceneText, s::AbstractString) = (item.o[:setText](s); item)

# -----------------------------------------------------------------------

# TODO: line's aren't centered currently, which will mess up scaling and rotating.. fix?

immutable Line <: SceneItem; o::PyObject; end
Line(p1::P2, p2::P2) = (l = Line(QT.QGraphicsLineItem(p1[1], p1[2], p2[1], p2[2])); zvalue!(l, -10000.0); l)
Line(p1::P3, p2::P3) = (l = Line(P2(p1), P2(p2)); zvalue!(l, (p1[3] + p2[3]) / 2.0 - 0.0001); l)

line!(scene::Scene, p1::Point, p2::Point) = push!(scene, Line(p1, p2))
line!(scene::Scene, x1::Real, y1::Real, x2::Real, y2::Real) = line!(scene, P2(x1,y1), P2(x2,y2))
line!(scene::Scene, item1::SceneItem, item2::SceneItem) = line!(scene, position3d(item1), position3d(item2))
line!(scene::Scene, p1::Point, item2::SceneItem) = line!(scene, P3(p1), position3d(item2))
line!(scene::Scene, item1::SceneItem, p2::Point) = line!(scene, position3d(item1), P3(p2))
line!(args...) = line!(currentScene(), args...)

# -----------------------------------------------------------------------

