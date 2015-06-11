import sys, os, time
from qwt_common import *
from pythonwidgets import *
import PyQt4.Qwt5 as Qwt
import scales
from PyQt4 import Qt, QtCore, QtGui
import numpy as np
import icons_rc


class YbPlotZoomer(Qwt.QwtPlotMagnifier):
    def __init__(self, plot, canvas):
        super(YbPlotZoomer, self).__init__(canvas)
        self.plot = plot
        self.setWheelFactor(0.9)
        self.setMouseButton(QtCore.Qt.NoButton)

    def widgetMouseReleaseEvent(self, e):
        if e.button() == QtCore.Qt.RightButton:
            for axis in [self.plot.yLeft, self.plot.yRight, self.plot.xTop, self.plot.xBottom]:
                self.plot.setAxisAutoScale(axis)
            self.plot.replot()
            e.accept()
        super(YbPlotZoomer, self).widgetMouseReleaseEvent(e)

    def widgetWheelEvent(self, e):
        self.setAxisEnabled(self.plot.xBottom, True)
        self.setAxisEnabled(self.plot.yLeft, True)
        self.setAxisEnabled(self.plot.yRight, True)
        if int(e.modifiers()) == QtCore.Qt.ShiftModifier + QtCore.Qt.ControlModifier:
            self.setAxisEnabled(self.plot.xBottom, False)
            self.setAxisEnabled(self.plot.yLeft, False)
        elif e.modifiers() & QtCore.Qt.ShiftModifier:
            self.setAxisEnabled(self.plot.xBottom, False)
            self.setAxisEnabled(self.plot.yRight, False)
        elif e.modifiers() & QtCore.Qt.ControlModifier:
            self.setAxisEnabled(self.plot.yLeft, False)
            self.setAxisEnabled(self.plot.yRight, False)

        evt2 = Qt.QWheelEvent(e.pos(), -e.delta(), e.buttons(), QtCore.Qt.NoModifier, e.orientation())
        super(YbPlotZoomer, self).widgetWheelEvent(evt2)

class YbPlotPanner(Qwt.QwtPlotPanner):
    def __init__(self, plot, canvas):
        super(YbPlotPanner, self).__init__(canvas)
        self.plot = plot

    def eventFilter(self, o, e):
        if e.type() == QtCore.QEvent.MouseButtonDblClick:
            xpct = float(e.pos().x()) / float(self.plot.canvas().width())
            ypct = 1.0 - float(e.pos().y()) / float(self.plot.canvas().height())
            
            if int(e.modifiers()) == QtCore.Qt.ShiftModifier + QtCore.Qt.ControlModifier:
                axes = [self.plot.yRight]
            elif e.modifiers() & QtCore.Qt.ShiftModifier:
                axes = [self.plot.yLeft]
            elif e.modifiers() & QtCore.Qt.ControlModifier:
                axes = [self.plot.xBottom]
            else:
                axes = [self.plot.xBottom, self.plot.yLeft, self.plot.yRight]

            for axis in axes:
                div = self.plot.axisScaleDiv(axis)
                lb = div.lowerBound()
                ub = div.upperBound()
                center = (lb + ub) / 2.0
                newcenter = (ub - lb) * (xpct if axis == self.plot.xBottom else ypct) + lb
                cdiff = newcenter - center
                self.plot.setAxisScale(axis, lb + cdiff, ub + cdiff)
                self.plot.replot()
        return super(YbPlotPanner, self).eventFilter(o, e)

    def widgetMousePressEvent(self, e):
        self.plot.canvas().setCursor(QtCore.Qt.ClosedHandCursor)
        super(YbPlotPanner, self).widgetMousePressEvent(e)

    def widgetMouseReleaseEvent(self, e):
        self.plot.canvas().setCursor(QtCore.Qt.CrossCursor)
        super(YbPlotPanner, self).widgetMouseReleaseEvent(e)

def feq(a,b):
    if abs(a-b) <= abs(a) * 1e-6:
        return 1
    else:
        return 0
def floatIn(val, l):
    for x in l:
        #print 'comparing',val,x,feq(val,x)
        if feq(val,x):
            return True
    return False

class YbPlotPiecewiseCurve(Qwt.QwtPlotCurve):
    def __init__(self, label, ignore, dots = False, symbol = None):
        super(YbPlotPiecewiseCurve, self).__init__(label)
        self.ignore = ignore  # if the data (y-axis) has this numeric value, the line won't be drawn
        self.dots = dots
        self.symbol = symbol

    def drawCurve(self, painter, style, xMap, yMap, fro, to):
        first = last = fro
        while last <= to:
            first = last
            #while first <= to and self.y(first) in self.ignore:
            while first <= to and floatIn(self.y(first), self.ignore):
                first += 1
            last = first
            #while last <= to and self.y(last) not in self.ignore:
            while last <= to and not floatIn(self.y(last), self.ignore):
                last += 1

            if self.symbol == None:
                if not self.dots and (first+1 < last):
                    super(YbPlotPiecewiseCurve, self).drawCurve(painter, style, xMap, yMap, first, last - 1)
                else:
                    super(YbPlotPiecewiseCurve, self).drawDots(painter, xMap, yMap, first, last - 1)

    def drawSymbols(self, painter, symbol, xMap, yMap, fro, to):
        i = fro
        while i <= to:
            #if self.y(i) not in self.ignore:
            if not floatIn(self.y(i), self.ignore):
                super(YbPlotPiecewiseCurve,self).drawSymbols(painter, symbol, xMap, yMap, i, i)
            i += 1

    def boundingRect(self):
        if self.dataSize() <= 0:
            return QtCore.QRectF(1.0, 1.0, -2.0, -2.0)  # empty data

        first = 0
        #while first < self.dataSize() and self.y(first) in self.ignore:
        while first < self.dataSize() and floatIn(self.y(first), self.ignore):
            first += 1
        if first == self.dataSize():
            return QtCore.QRectF(1.0, 1.0, -2.0, -2.0)    # empty data

        minX = maxX = self.x(first)
        minY = maxY = self.y(first)
        for i in range(first + 1, self.dataSize()):
            xv = self.x(i)
            if xv < minX: minX = xv
            if xv > maxX: maxX = xv
            yv = self.y(i)
            #if yv in self.ignore: continue   # skip it
            if floatIn(yv, self.ignore): continue   # skip it
            if yv < minY: minY = yv
            if yv > maxY: maxY = yv
        rect = QtCore.QRectF(minX, minY, maxX - minX, maxY - minY)
        return rect

class YbPlot(Qwt.QwtPlot):
    def __init__(self, useAA = True, zoomer = True, panner = True, picker = True, capture = True):
        Qwt.QwtPlot.__init__(self)

        self.useAA = useAA    # use anti-aliasing for the graph lines
        if os.environ.get('USER','') == 'bmh': self.useAA = True

        self.axisScaleDraw(self.yLeft).setMinimumExtent(70)

        # Initialize data
        self.x = []

        # lists of data
        self.y = []
        self.yAxis2 = []
        self.yFit = []
        self.yAxis2Fit = []
        self.curvesAxis1 = []
        self.curvesAxis2 = []
        self.curvesAxis1Fit = []
        self.curvesAxis2Fit = []

        if panner:
            self.panner = YbPlotPanner(self, self.canvas())
            self.panner.setEnabled(True)

        if zoomer:
            self.zoomer = YbPlotZoomer(self, self.canvas())

        self.setCanvasBackground(Qt.Qt.white)
        self.legend = Qwt.QwtLegend()
        self.legend.setItemMode(self.legend.CheckableItem)
        self.legendChecked.connect(self.legendCheckedSlot)
        self.insertLegend(self.legend, Qwt.QwtPlot.BottomLegend);

        # axes
        self.setAxisTitle(Qwt.QwtPlot.yLeft, "")

        self.setMinimumSize(1,1)

        # our counter
        self.i = 0

        if capture:
            self.captureBtn = QtGui.QPushButton(parent=self)
            self.captureBtn.setIcon(QtGui.QIcon(':/16/opt/icons/color/16/camera16.png'))
            self.captureBtn.setStyleSheet("padding:0; margin:0")
            self.captureBtn.setFixedSize(20,20)
            self.captureBtn.clicked.connect(self.capture)
        self.setTitle('')

        ### grid
        pen = Qt.QPen()
        pen.setColor(Qt.QColor(100,100,100,110))
        pen.setWidth(4)
        pen2 = Qt.QPen(Qt.Qt.DotLine)
        pen2.setColor(Qt.QColor(100,100,100,255))
        pen2.setWidth(1)
        self.gridDay = Qwt.QwtPlotGrid()
        self.gridDay.setMajPen(pen)
        self.gridDay.setMinPen(pen2)
        self.gridDay.setRenderHint(self.gridDay.RenderAntialiased)
        self.gridDay.enableX(True)
        self.gridDay.enableXMin(True)
        self.gridDay.enableY(False)
        self.gridDay.setItemAttribute(self.gridDay.AutoScale, False)
        self.gridDay.attach(self)

        pen3 = Qt.QPen(Qt.Qt.DotLine)
        pen3.setColor(Qt.QColor(180,180,180,255))
        pen3.setWidth(1)
        self.gridHoriz = Qwt.QwtPlotGrid()
        self.gridHoriz.setPen(pen3)
        self.gridHoriz.setRenderHint(self.gridHoriz.RenderAntialiased)
        self.gridHoriz.enableX(False)
        self.gridHoriz.attach(self)

    def setTitle(self, title):
        self.titleStr = title

    def capture(self):
        popup = False
        fn = '/ybdata/log/SIM/captures/%s_%s.png' % (getTime("%Y-%m-%d_%H%M%S"), self.titleStr)
        if QtGui.QApplication.keyboardModifiers() == QtCore.Qt.ShiftModifier:
            userFn = QtGui.QFileDialog.getSaveFileName(self, "Save As", fn, "PNG Files (*.png);;All Files (*)")
            if userFn != "":
                fn = userFn
            else:
                return
        else:
            popup = True

        self.captureBtn.hide()
        super(YbPlot, self).setTitle(self.titleStr)
        pixmap = QtGui.QPixmap.grabWidget(self)
        super(YbPlot, self).setTitle("")
        self.captureBtn.show()
        
        pixmap.save(fn, "png")
        print "Saved a graph screen capture as: %s" % fn

        # open a window with the image
        if popup:
            os.system("eog %s&" % fn)

    def resizeEvent(self, e):
        super(YbPlot, self).resizeEvent(e)
        bl = self.rect().bottomLeft()
        self.captureBtn.move(bl.x(), bl.y() - 18)

    def legendCheckedSlot(self, curve, on):
        curve.setVisible(not on)
        curve.setItemAttribute(curve.AutoScale, not on)
        self.replot()

    def setXAxisDateTimeScale(self):
        scales.DateTimeScaleEngine2.enableInAxis(self, Qwt.QwtPlot.xBottom)
        self.picker = scales.YbPlotPicker(self, (self.xBottom, self.yLeft, Qwt.QwtPicker.PointSelection, Qwt.QwtPlotPicker.CrossRubberBand, Qwt.QwtPicker.AlwaysOn, self.canvas()))
        self.picker.setTrackerFont(QtGui.QFont('Terminus', 8))
        self.picker.setTrackerPen(QtGui.QPen(Qt.Qt.black))
        self.canvas().setCursor(QtCore.Qt.CrossCursor)

    def addLine(self, firstAxis = True, color = Qt.Qt.red, label = "Data y", width = 2, dotStyle = None, step = False, fill = None, fit = False, show = True, stepInverted = True, ignore = None, dots = False, symbol = None, symbolSize = 8, zIndex = 1):
        if ignore != None or dots:
            curve = YbPlotPiecewiseCurve(label, ignore, dots, symbol)  # pass through the value to 'ignore' when drawing
        else:
            curve = Qwt.QwtPlotCurve(label)

        if self.useAA:
            curve.setRenderHint(curve.RenderAntialiased)
        
        if step:
            curve.setStyle(curve.Steps)
            curve.setCurveAttribute(Qwt.QwtPlotCurve.Inverted, stepInverted)

        if dotStyle == None:
            if firstAxis:   dotStyle = Qt.Qt.SolidLine
            else:           dotStyle = Qt.Qt.SolidLine
        curve.setPen(Qt.QPen(color, width, dotStyle))

        if symbol != None:
            icon = Qwt.QwtSymbol()
            iconMap = { 'ellipse': icon.Ellipse,
                        'rect': icon.Rect,
                        'diamond': icon.Diamond,
                        'triangle': icon.Triangle,
                        'triangledown': icon.DTriangle,
                        'triangleup': icon.UTriangle,
                        'triangleleft': icon.LTriangle,
                        'triangleright': icon.RTriangle,
                        'cross': icon.Cross,
                        'x': icon.XCross,
                        'hline': icon.HLine,
                        'vline': icon.VLine,
                        '*': icon.Star1,
                        'star': icon.Star2,
                        'hex': icon.Hexagon
                      }
            icon.setStyle(iconMap.get(symbol,icon.Star1))
            icon.setSize(symbolSize)
            icon.setPen(Qt.QPen(color, width, dotStyle))
            icon.setBrush(Qt.QBrush(color, QtCore.Qt.SolidPattern))
            curve.setSymbol(icon)
            curve.setStyle(curve.NoCurve)

        if fill != None:   # an integer specifying the fill baseline, often 0
            curve.setBaseline(fill)
            curve.setBrush(Qt.QBrush(color, QtCore.Qt.SolidPattern))

        if not show:
            curve.setVisible(False)
            curve.setItemAttribute(curve.AutoScale, False)
            curve.setItemAttribute(curve.Legend, False)

        curve.setZ(zIndex)

        curve.attach(self)

        if firstAxis:
            curve.setYAxis(Qwt.QwtPlot.yLeft)
            if fit:
                self.yFit.append([])
                self.curvesAxis1Fit.append(curve)
            else:
                curve.setZ(float(len(self.y)))
                self.y.append([])
                self.curvesAxis1.append(curve)
        else:
            curve.setYAxis(Qwt.QwtPlot.yRight)
            if len(self.yAxis2) == 0:
                # init 2nd axis
                self.enableAxis(Qwt.QwtPlot.yRight)
                self.setAxisTitle(Qwt.QwtPlot.yRight, "y2 (a.u.)")
            if fit:
                self.yAxis2Fit.append([])
                self.curvesAxis2Fit.append(curve)
            else:
                curve.setZ(float(len(self.yAxis2)) - 100.0)
                self.yAxis2.append([])
                self.curvesAxis2.append(curve)

    def clearAll(self):
        self.x = []
        self.y = []
        self.yAxis2 = []
        self.yFit = []
        self.yAxis2Fit = []
        for axis in [self.curvesAxis1, self.curvesAxis2, self.curvesAxis1Fit, self.curvesAxis2Fit]:
            for i in range(len(axis)):
                axis[i].detach()
        self.curvesAxis1 = []
        self.curvesAxis2 = []
        self.curvesAxis1Fit = []
        self.curvesAxis2Fit = []
        self.i = 0

    def clearData(self):
        self.x = []
        for axis in [self.y, self.yAxis2, self.yFit, self.yAxis2Fit]:
            for i in range(len(axis)):
                axis[i] = []

    def updateGraph(self):
        for i in range(len(self.y)):
            self.curvesAxis1[i].setData(self.x, self.y[i])
        for i in range(len(self.yAxis2)):
            self.curvesAxis2[i].setData(self.x, self.yAxis2[i])
        for i in range(len(self.yFit)):
            self.curvesAxis1Fit[i].setData(self.x, self.yFit[i])
        for i in range(len(self.yAxis2Fit)):
            self.curvesAxis2Fit[i].setData(self.x, self.yAxis2Fit[i])

        #mn = self.x[0]
        #mx = self.x[-1]
        #minor = []
        #med = []
        #if mx - mn <= 7:
        #    print '\n\nsmall grid\n\n\n', mn, mx
        #    self.gridDay.setVisible(True)
        #    self.gridWk.setVisible(False)
        #else:
        #    print '\n\nlarge grid\n\n\n', mn, mx
        #    self.gridDay.setVisible(False)
        #    self.gridWk.setVisible(True)


        ### redraw
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

    def updateData(self):
        pass

    def limitData(self, window = 100):
        self.x = self.x[-window:]
        for i in range(len(self.y)):
            self.y[i] = self.y[i][-window:]
        for i in range(len(self.yAxis2)):
            self.yAxis2[i] = self.yAxis2[i][-window:]

    def timerEvent(self, e):
        self.updateData()
        self.updateGraph()
        self.i += 1

# create widgets like this:
class myExamplePlot(YbPlot):
    def __init__(self):
        YbPlot.__init__(self)

        # call addLine for each curve on the graph
        self.addLine(firstAxis = True, color = Qt.Qt.red, label = "y1")
        self.addLine(firstAxis = True, color = Qt.Qt.blue, label = "y2")
        self.addLine(firstAxis = False, color = Qt.Qt.green, label = "y3")

        # start a 5 millisecond timer which will call updateData on each pass
        # self.startTimer(5)
        for i in range(100):
            self.updateData()

    # reimplements the function from myPlot
    def updateData(self):
        self.x.append(self.i)
        self.y[0].append(self.i % 20)
        self.y[1].append((self.i*2) % 10)
        self.yAxis2[0].append((self.i*20) % 100)

        # limits to the last 100 data points
        self.limitData(100)
        
if __name__ == '__main__':
    app = Qt.QApplication([])
    p=myExamplePlot()
    p.resize(500,300)
    p.show()
    app.exec_()
