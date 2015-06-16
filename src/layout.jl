
# -----------------------------------------------------------------------

type Layout <: Widget
  widget::PyObject  # QFrame with the given layout
  children::Vector{Widget}
end


function Layout(isvert::Bool, children::Widget...)
  
  layout = Layout(QT.QFrame(), Widget[])
  qlayout = isvert ? QT.QVBoxLayout() : QT.QHBoxLayout()
  layout.widget[:setLayout](qlayout)
  for child in children
    push!(layout.children, child)
    qlayout[:addWidget](child.widget)
  end
  layout
end

vbox(args...) = Layout(true, args...)
hbox(args...) = Layout(false, args...)


type Splitter <: Widget
  widget::PyObject  # QSplitter
  children::Vector{Widget}
end

function Splitter(isvert::Bool, children::Widget...)
  splitter = Splitter(QT.QSplitter(isvert ? 2 : 1), Widget[])
  for child in children
    push!(splitter.children, child)
    splitter.widget[:addWidget](child.widget)
  end
  splitter
end

vsplitter(args...) = Splitter(true, args...)
hsplitter(args...) = Splitter(false, args...)


