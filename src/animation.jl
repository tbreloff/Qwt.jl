
# import Glob

type PlotAnimation
  t::Int
  widget::Widget
  dir::ASCIIString
end

function animation(widget::Widget, dir::ASCIIString)

  # remove existing pngs
  dir = string(dir, "/")
  #map(rm, Glob.glob("qtanim*.png", dir))

  PlotAnimation(1, widget, dir)
end

function saveframe(animation::PlotAnimation)
  savepng(animation.widget, string(animation.dir, @sprintf("qtanim%04d.png", animation.t)))
  animation.t += 1
end

makegif(animation::PlotAnimation) = run(`ffmpeg -framerate 20 -i $(animation.dir)/qtanim%04d.png -y $(animation.dir)/out.gif`)

