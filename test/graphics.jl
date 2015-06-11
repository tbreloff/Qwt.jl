

module graphics

# reload("Qwt")
using Qwt

# -----------------------------------------------------------------------

type Scene
	v # qt view
	s # qt scene
	items::Vector
end
function Scene(x::Int = 2000, y::Int = 0, w::Int = 1000, h::Int = 600)
	s = Qwt.QT.QGraphicsScene()
	v = Qwt.QT.QGraphicsView(s)
	v[:setGeometry](x,y,w,h)
	Qwt.showwidget(v)
	Scene(v, s, [])
end

function Base.empty!(scene::Scene)
	empty!(scene.items)
	scene.s[:clear]()
end

# -----------------------------------------------------------------------

abstract SceneItem

function Base.push!(scene::Scene, item::SceneItem)
	scene.s[:addItem](item.o)
	push!(scene.items, item)
end

moveby(item::SceneItem, x, y) = item.o[:moveBy](float(x), float(y))
scale(item::SceneItem, x, y) = item.o[:scale](float(x), float(y))
rotate(item::SceneItem, deg) = item.o[:setRotation](deg + item.o[:rotation]())

# TODO set parent... transforms coordinates relative to parent

# -----------------------------------------------------------------------

type Ellipse <: SceneItem
	o  # qt object
	function Ellipse(centerx, centery, radiusx, radiusy)
		new(Qwt.QT.QGraphicsEllipseItem(map(float, (centerx-radiusx, centery-radiusy, radiusx*2, radiusy*2))...))
	end
end

Circle(centerx, centery, radius) = Ellipse(centerx, centery, radius, radius)

# -----------------------------------------------------------------------



end

g = graphics