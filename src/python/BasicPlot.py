import sys, os, time
import PyQt4.Qwt5 as Qwt
from PyQt4 import Qt
import numpy as np

# this is a bare bones wrapper around Qwt5's plotting
# it was built to be called from Julia code, and doesn't have full functionality by itself
# includes left and right axis support, zooming, panning, etc

# ZOOMING
# click and drag with the left mouse button to select a rectangle to zoom into
# to undo 1 zoom, hold ALT and click the right mouse button
# to redo 1 zoom, hold SHIFT and click the right mouse button
# to reset the zoom stack, click the middle mouse button

# PANNING
# click and drag with the right mouse button

class EmptyWidget(Qt.QWidget):
    def __init__(self):
        super(EmptyWidget, self).__init__()



class SubplotWidget(Qt.QWidget):
    def __init__(self):
        super(SubplotWidget, self).__init__()
        self.hbox = Qt.QHBoxLayout(self)
        self.setLayout(self.hbox)
        self.doinit()

    def doinit(self):
        self.container = Qt.QSplitter(Qt.Qt.Vertical)
        self.hbox.addWidget(self.container)

    def clearhbox(self):
        self.hbox.removeWidget(self.container)
        self.container.setParent(None)
        self.container = None

    # we expects figs to be nested BasicPlots (i.e. [[plt1, plt2], [plt3, None]] would give 2 rows, where plt1/2 are
    # in the first row and plt3 takes up the 3rd)
    def addFigures(self, figs):

        self.clearhbox()
        self.doinit()

        rows = []
        for row in figs:
            splitterHorizontal = Qt.QSplitter(Qt.Qt.Horizontal)
            for plt in row:
                if plt != None:
                    splitterHorizontal.addWidget(plt)
            self.container.addWidget(splitterHorizontal)


# create a class to override QwtColorMap and which gives RGB values:
#   R is always 255
#   G is 255 if below some cutoff C (=0.25?), then scales linearly to 0 from C to 1.0
#   B is 0 if above C, then scales linearly from 0.0 to C

def getcolor(ratio, yellowCutoff, orangeCutoff):
    
    green = 255
    if ratio > orangeCutoff:
        green = max(0, int(128 * (1-ratio)/(1-orangeCutoff)))
    elif ratio > yellowCutoff:
        green = max(0, 128 + int(127 * (orangeCutoff-ratio)/(orangeCutoff-yellowCutoff)))

    blue = 0
    if ratio < yellowCutoff:
        blue = min(255, int(255 * (1 - ratio / yellowCutoff)))
    
    return Qt.QColor(255, green, blue)


def getcolormap(yellowCutoff = 0.15, orangeCutoff = 0.5):    
    colmap = Qwt.QwtLinearColorMap(Qt.Qt.gray, Qt.Qt.gray)
    for x in np.linspace(0, 1, 100):
        colmap.addColorStop(x, getcolor(x, yellowCutoff, orangeCutoff))
    return colmap


class HeatMapData(Qwt.QwtRasterData):
    def __init__(self, x, y, nx, ny):
        Qwt.QwtRasterData.__init__(self, Qt.QRectF(min(x), min(y), max(x)-min(x), max(y)-min(y)))

        self.x = x
        self.y = y
        self.nx = nx
        self.ny = ny

        self.minx = min(x)
        self.miny = min(y)
        self.maxx = max(x)
        self.maxy = max(y)

        # print self.minx, self.miny, self.maxx, self.maxy

        # self.n = 200 # number of rows/cols
        self.zmat = np.zeros((self.nx, self.ny))
        for i in range(len(x)):
            xidx = self.getIndexX(x[i], self.minx, self.maxx)
            yidx = self.getIndexY(y[i], self.miny, self.maxy)
            self.zmat[xidx,yidx] += 1.0

        # now scale the matrix down by the max
        self.zmat /= np.max(self.zmat)

    def getIndexX(self, v, minv, maxv):
        if v >= maxv:
            return self.nx - 1
        elif v <= minv:
            return 0

        ratio = (v - minv) / (maxv - minv)
        return int(self.nx * ratio)

    def getIndexY(self, v, minv, maxv):
        if v >= maxv:
            return self.ny - 1
        elif v <= minv:
            return 0

        ratio = (v - minv) / (maxv - minv)
        return int(self.ny * ratio)

    # i think this returns the z-range
    def range(self):
        # print "range"
        return Qwt.QwtDoubleInterval(0.0, 1.0)

    def copy(self):
        # print "copy"
        return HeatMapData(self.x, self.y, self.nx, self.ny)

    def value(self, x, y):
        # print "value", x, y
        if x < self.minx or x > self.maxx or y < self.miny or y > self.maxy:
            return 0.0

        xidx = self.getIndexX(x, self.minx, self.maxx)
        yidx = self.getIndexY(y, self.miny, self.maxy)
        # print "idx", xidx, yidx
        return self.zmat[xidx, yidx]





class BasicPlot(Qwt.QwtPlot):
    def __init__(self):
        Qwt.QwtPlot.__init__(self)

        self.enableAxis(Qwt.QwtPlot.yLeft, False)
        self.enableAxis(Qwt.QwtPlot.yRight, False)

        self.curvesAxis1 = []
        self.curvesAxis2 = []

        self.setCanvasBackground(Qt.Qt.white)

        # self.legend = Qwt.QwtLegend()
        # self.legend.setItemMode(Qwt.QwtLegend.ClickableItem)
        # # Qt.QObject.connect(self, Qt.SIGNAL("legendClicked(QwtPlotItem*)"), self.legendclick)
        # self.legendClicked.connect(self.legendclick)
        # # self.insertLegend(self.legend, Qwt.QwtPlot.BottomLegend);

        self.legendShown = False
        self.showLegend()

        # legend
        #legend = Qwt.QwtLegend()
        #self.insertLegend(legend, Qwt.QwtPlot.RightLegend)
        #self.insertLegend(legend, Qwt.QwtPlot.BottomLegend)

        # grid
        grid = Qwt.QwtPlotGrid()
        pen = Qt.QPen(Qt.Qt.DotLine)
        pen.setColor(Qt.Qt.black)
        pen.setWidth(0)
        grid.setPen(pen)
        grid.attach(self)

        #self.resize(100,100)

        self.zoomers = []
        self.__initZooming()
        self.__initPanning()

    def hideLegend(self):
        if self.legendShown:
            self.insertLegend(None)
            self.legendShown = False

    def showLegend(self):
        if not self.legendShown:
            self.legend = Qwt.QwtLegend()
            self.legend.setItemMode(Qwt.QwtLegend.ClickableItem)
            self.legendClicked.connect(self.legendclick)
            self.insertLegend(self.legend, Qwt.QwtPlot.BottomLegend)
            self.legendShown = True


    def legendclick(self, item):
        if item.isVisible():
            item.hide()
        else:
            item.show()
        item.setItemAttribute(Qwt.QwtPlotItem.AutoScale, item.isVisible())
        self.startUpdate()
        self.finishUpdate()

    def __initZooming(self):

        zoomer = Qwt.QwtPlotZoomer(Qwt.QwtPlot.xBottom,
                                    Qwt.QwtPlot.yLeft,
                                    Qwt.QwtPicker.DragSelection,
                                    Qwt.QwtPicker.AlwaysOff,
                                    self.canvas())
        zoomer.setRubberBandPen(Qt.QPen(Qt.Qt.black))
        self.zoomers.append(zoomer)
        zoomer = Qwt.QwtPlotZoomer(Qwt.QwtPlot.xTop,
                                    Qwt.QwtPlot.yRight,
                                    Qwt.QwtPicker.DragSelection,
                                    Qwt.QwtPicker.AlwaysOff,
                                    self.canvas())
        zoomer.setRubberBand(Qwt.QwtPicker.NoRubberBand)
        self.zoomers.append(zoomer)

        pattern = [
                Qwt.QwtEventPattern.MousePattern(Qt.Qt.LeftButton, Qt.Qt.NoModifier), 
                Qwt.QwtEventPattern.MousePattern(Qt.Qt.MidButton, Qt.Qt.NoModifier),
                Qwt.QwtEventPattern.MousePattern(Qt.Qt.RightButton, Qt.Qt.AltModifier),
                Qwt.QwtEventPattern.MousePattern(Qt.Qt.LeftButton, Qt.Qt.ShiftModifier),
                Qwt.QwtEventPattern.MousePattern(Qt.Qt.MidButton, Qt.Qt.ShiftModifier),
                Qwt.QwtEventPattern.MousePattern(Qt.Qt.RightButton, Qt.Qt.ShiftModifier),
                ]
        for zoomer in self.zoomers:
            zoomer.setMousePattern(pattern)


    def __initPanning(self):
        self.panner = Qwt.QwtPlotPanner(self.canvas())
        self.panner.setMouseButton(Qt.Qt.RightButton)

    def getLineType(self, linetype):
        if linetype == "line": return Qwt.QwtPlotCurve.Lines
        if linetype == "step": return Qwt.QwtPlotCurve.Steps
        if linetype == "stepinverted": return Qwt.QwtPlotCurve.Steps
        if linetype == "sticks": return Qwt.QwtPlotCurve.Sticks
        if linetype == "dots": return Qwt.QwtPlotCurve.Dots
        if linetype == "none": return Qwt.QwtPlotCurve.NoCurve
        else: raise Exception("Invalid linetype: " + linetype)

    def getLineStyle(self, linestyle):
        if linestyle == "solid": return Qt.Qt.SolidLine
        if linestyle == "dash": return Qt.Qt.DashLine
        if linestyle == "dot": return Qt.Qt.DotLine
        if linestyle == "dashdot": return Qt.Qt.DashDotLine
        if linestyle == "dashdotdot": return Qt.Qt.DashDotDotLine
        else: raise Exception("Invalid linestyle: " + linestyle)

    def getMarkerType(self, markertype):
        if markertype == "ellipse": return Qwt.QwtSymbol.Ellipse
        if markertype == "rect": return Qwt.QwtSymbol.Rect
        if markertype == "diamond": return Qwt.QwtSymbol.Diamond
        if markertype == "utriangle": return Qwt.QwtSymbol.UTriangle
        if markertype == "dtriangle": return Qwt.QwtSymbol.DTriangle
        if markertype == "cross": return Qwt.QwtSymbol.Cross
        if markertype == "xcross": return Qwt.QwtSymbol.XCross
        if markertype == "star1": return Qwt.QwtSymbol.Star1
        if markertype == "star2": return Qwt.QwtSymbol.Star2
        if markertype == "hexagon": return Qwt.QwtSymbol.Hexagon
        else: raise Exception("Invalid markertype: " + markertype)

    def setAxisAutoScales(self):
        self.setAxisAutoScale(Qwt.QwtPlot.xBottom)
        self.setAxisAutoScale(Qwt.QwtPlot.xTop)
        self.setAxisAutoScale(Qwt.QwtPlot.yLeft)
        self.setAxisAutoScale(Qwt.QwtPlot.yRight)

    def addLine(self, left = True, width = 2, markersize = 10, color = "black", label = "y", linetype = "line", linestyle = "solid", marker = "none", markercolor = "black", fillto = None, fillcolor = None):
        self.setAxisAutoScales()
        curve = Qwt.QwtPlotCurve(label)
        axis = Qwt.QwtPlot.yLeft if left else Qwt.QwtPlot.yRight
        self.enableAxis(axis)
        curve.setYAxis(axis)
        curve.setPen(Qt.QPen(Qt.QColor(color), width, self.getLineStyle(linestyle)))
        curve.setStyle(self.getLineType(linetype))
        if linetype == "step": # NOTE: i think "stepinverted" should be the standard, so i switched names!
            curve.setCurveAttribute(Qwt.QwtPlotCurve.Inverted)
        if marker != "none":
            mcolor = Qt.QColor(markercolor)
            interiorBrush = Qt.QBrush(mcolor)
            borderPen = Qt.QPen(mcolor, 1, Qt.Qt.SolidLine)
            curve.setSymbol(Qwt.QwtSymbol(self.getMarkerType(marker), interiorBrush, borderPen, Qt.QSize(markersize,markersize)))
        if fillto != None:
            if fillcolor == None:
                curve.setBrush(Qt.QColor(color))
            else:
                curve.setBrush(Qt.QColor(fillcolor))
            curve.setBaseline(fillto)
        curve.attach(self)

        if left:
            self.curvesAxis1.append(curve)
        else:
            self.curvesAxis2.append(curve)

    def addHeatMap(self, left = True, label = "y", yellowCutoff = 0.15, orangeCutoff = 0.5):
        self.setAxisAutoScales()
        spectrogram = Qwt.QwtPlotSpectrogram(label)
        
        colmap = getcolormap(yellowCutoff, orangeCutoff)
        spectrogram.setColorMap(colmap)
        
        axis = Qwt.QwtPlot.yLeft if left else Qwt.QwtPlot.yRight
        self.enableAxis(axis)
        spectrogram.setYAxis(axis)
        
        spectrogram.attach(self)
        if left:
            self.curvesAxis1.append(spectrogram)
        else:
            self.curvesAxis2.append(spectrogram)


    def startUpdate(self, autox = True, autoy = True):
        if autox:
            self.setAxisAutoScale(Qwt.QwtPlot.xBottom)
            self.setAxisAutoScale(Qwt.QwtPlot.xTop)
        if autoy:
            self.setAxisAutoScale(Qwt.QwtPlot.yLeft)
            self.setAxisAutoScale(Qwt.QwtPlot.yRight)
        # for axis in [Qwt.QwtPlot.xBottom, Qwt.QwtPlot.xTop, Qwt.QwtPlot.yLeft, Qwt.QwtPlot.yRight]:
        #     self.setAxisAutoScale(axis)

    def finishUpdate(self):
        for zoomer in self.zoomers:
            zoomer.setZoomBase()
        self.replot()

    def setATitle(self, axis, title): # axis = x,y,y2
        title = ""+title+"" # you may want this to be a bigger value...
        if axis == "x" :
            self.setAxisTitle(Qwt.QwtPlot.xBottom, title)
        elif axis == "y" :
            self.setAxisTitle(Qwt.QwtPlot.yLeft, title)
        elif axis == "y2" :
            self.setAxisTitle(Qwt.QwtPlot.yRight, title)
        else:
            return 0

    def setXAxisTitle(self, title):
        title = ""+title+""
        self.setAxisTitle(Qwt.QwtPlot.xBottom, title)

    def setYAxisTitle(self, title):
        title = ""+title+""
        self.setAxisTitle(Qwt.QwtPlot.yLeft, title)

    def setYAxisTitleRight(self, title):
        title = ""+title+""
        self.setAxisTitle(Qwt.QwtPlot.yRight, title)

    def setPlotTitle(self, title):
        title = ""+title+""
        self.setTitle(title)


