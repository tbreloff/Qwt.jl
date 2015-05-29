
import Glob

type PlotAnimation
	t::Int
	plt::PlotWidget
	dir::ASCIIString
end

function animation(plt::PlotWidget, dir::ASCIIString)

	# remove existing pngs
	dir = string(dir, "/")
	map(rm, Glob.glob("plot*.png", dir))

	PlotAnimation(1, plt, dir)
end

function saveframe(animation::PlotAnimation)
	savepng(animation.plt, string(animation.dir, @sprintf("plot%04d.png", animation.t)))
	animation.t += 1
end

makegif(animation::PlotAnimation) = run(`ffmpeg -framerate 20 -i $(animation.dir)/plot%04d.png -y $(animation.dir)/out.gif`)

