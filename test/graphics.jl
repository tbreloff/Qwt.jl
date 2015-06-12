

module graphics

# reload("Qwt")
using Qwt

immutable Point2
	x::Float64
	y::Float64
end

Point2(o::Qwt.PyObject) = Point2(o[:x](), o[:y]())

immutable Point3
	x::Float64
	y::Float64
	z::Float64
end

# -----------------------------------------------------------------------

immutable Scene
	widget # qt view
	s # qt scene
	items::Vector
end
# function Scene(x::Int = 2000, y::Int = 0, w::Int = 1000, h::Int = 600)
function Scene(pos::Point2 = Point2(2000,0), sz::Point2 = Point2(1000,600))
	s = Qwt.QT.QGraphicsScene()
	widget = Qwt.QT.QGraphicsView(s)
	widget[:setGeometry](pos.x, pos.y, sz.x, sz.y)
	Qwt.showwidget(widget)
	Scene(widget, s, SceneItem[])
end

function Base.empty!(scene::Scene)
	empty!(scene.items)
	scene.s[:clear]()
end

showwidget(scene::Scene) = showwidget(scene.widget)
hidewidget(scene::Scene) = hidewidget(scene.widget)
widgetpos(scene::Scene) = widgetpos(scene.widget)
widgetsize(scene::Scene) = widgetsize(scene.widget)
movewidget(scene::Scene, x::Int, y::Int) = movewidget(scene.widget, x, y)
resizewidget(scene::Scene, width::Int, height::Int) = resizewidget(scene.widget, width, height)
move_resizewidget(scene::Scene, x::Int, y::Int, width::Int, height::Int) = move_resizewidget(scene.widget, x, y, width, height)

# -----------------------------------------------------------------------

function makebrush(color::Symbol)
	@assert color in Qwt.COLORS
	Qwt.QT.QBrush(Qwt.QT.QColor(string(color)))
end

function makepen(color::Symbol, width::Float64)
	@assert color in Qwt.COLORS
	Qwt.QT.QPen(makebrush(color), width)
end

# -----------------------------------------------------------------------

abstract SceneItem

function Base.push!(scene::Scene, item::SceneItem)
	scene.s[:addItem](item.o)
	push!(scene.items, item)
	item
end

Base.position(item::SceneItem) = Point2(item.o[:rect]())
position!(item::SceneItem, p::Point2) = item.o[:setPos](p.x, p.y)
center(item::SceneItem) = Point2(item.o[:boundingRect]()[:center]())
zvalue(item::SceneItem) = item.o[:zValue]()
zvalue!(item::SceneItem, z::Real) = item.o[:setZValue](float(z))
rotation(item::SceneItem) = item.o[:rotation]()
rotation!(item::SceneItem, deg::Real) = item.o[:setRotation](float(deg))
visible(item::SceneItem) = item.o[:isVisible]()
visible!(item::SceneItem, b::Bool) = item.o[:setVisible](b)
parent(item::SceneItem) = item.o[:parentItem]()
parent!(item::SceneItem, parent::SceneItem) = item.o[:setParentItem](parent.o)

brush!(item::SceneItem, color::Symbol) = brush!(item, makebrush(color))
brush!(item::SceneItem, brush::Qwt.PyObject) = item.o[:setBrush](brush)
pen!(item::SceneItem, color::Symbol, width::Int = 3) = pen!(item, makepen(color, width))
pen!(item::SceneItem, pen::Qwt.PyObject) = item.o[:setPen](pen)

# these are relative changes
move!(item::SceneItem, p::Point2) = item.o[:moveBy](p.x, p.y)
movex!(item::SceneItem, x::Real) = move!(item, Point2(x, 0))
movey!(item::SceneItem, y::Real) = move!(item, Point2(0, y))
scale!(item::SceneItem, p::Point2) = item.o[:scale](p.x, p.y)
scale!(item::SceneItem, s::Real) = scale!(item, Point2(s, s))
scalex!(item::SceneItem, x::Real) = scale!(item, Point2(x, 0))
scaley!(item::SceneItem, y::Real) = scale!(item, Point2(y, 0))
rotate!(item::SceneItem, deg::Real) = rotation!(item, deg + rotation(item))

# create a new line connecting 2 items
connect!(scene::Scene, item1::SceneItem, item2::SceneItem) = connect!(scene, center(item1), center(item2))
connect!(scene::Scene, p1::Point2, p2::Point2) = push!(scene, Line(p1, p2))

# -----------------------------------------------------------------------

immutable Ellipse <: SceneItem; o::Qwt.PyObject; end
Ellipse(center::Point2, radius::Point2) = Ellipse(Qwt.QT.QGraphicsEllipseItem(center.x-radius.x, center.y-radius.y, radius.x*2, radius.y*2))
Circle(centerx::Point2, radius::Real) = Ellipse(center, Point2(radius, radius))

# -----------------------------------------------------------------------

immutable Rect <: SceneItem; o::Qwt.PyObject; end
Rect(pos::Point2, sz::Point2) = Rect(Qwt.QT.QGraphicsRectItem(pos.x, pos.y, sz.x, sz.y))
Square(pos::Point2, w::Real) = Rect(pos, Point2(w, w))

# -----------------------------------------------------------------------

immutable Text <: SceneItem; o::Qwt.PyObject; end
Text(s::String, pos::Point2) = (o = Qwt.QT.QGraphicsSimpleTextItem(s); o[:setPosition](pos.x, pos.y); Text(o))

# -----------------------------------------------------------------------

immutable Line <: SceneItem; o::Qwt.PyObject; end
Line(p1::Point2, p2::Point2) = Line(Qwt.QT.QGraphicsLineItem(p1.x, p1.y, p2.x, p2.y))

# -----------------------------------------------------------------------


end

g = graphics