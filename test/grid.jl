
using Qwt

scene = currentScene()
empty!(scene)
background!(:gray)

# draw axes.. by default it adds to current scene, but could pass scene as optional first arg
line!(0, top(scene), 0, bottom(scene))
line!(left(scene), 0, right(scene), 0)

# cube of circles... connect all with lines
startpos = P3(-300, -300, -300)
endpos = P3(300, 300, 300)
pdiff = endpos - startpos
n = 3
r = maximum(pdiff) / n / 5

# create the circles
circles = Array(Any, n, n, n)
for i in 1:n
  for j in 1:n
    for k in 1:n
      # layout in a grid
      pos = startpos + (P3(i,j,k) - 1) .* pdiff ./ (n-1)

      # shift x/y coords based on zvalue to give a 3d-ish look
      z = pos[3]
      pos = pos + P3(z/8, z/6, 0)

      c = circles[i,j,k] = circle!(r, pos)
      brush!(pen!(c, 0), :lightGray)
    end
  end
end

# connect them randomly with lines (note the proper overlap based on z value)
for c1 in circles
  for c2 in circles
    if rand() < 0.2
      l = line!(c1,c2)
      pen!(l, 2, 0, rand(), .8, .2)
    end
  end
end

# pretty lights :)
for i in 1:500
  map(x->brush!(x, rand(3)...), circles)
  sleep(0.01)
end


# # draw a square
# s1 = square!(100)

# # make it rotate in a loop
# for i in 1:500
#   rotate!(s1, 1)
#   sleep(0.01)
# end