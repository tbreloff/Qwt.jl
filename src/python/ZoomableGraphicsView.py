from pythonwidgets import *
# import GraphicsItems

class ZoomableGraphicsView(QGraphicsView):

    def __init__(self, main, viewId):
        super(QGraphicsView, self).__init__()

        self.main = main
        self.viewId = viewId
        self.setCursor(Qt.OpenHandCursor)
        self.setResizeAnchor(QGraphicsView.AnchorUnderMouse)
        self.dragging = False
        if self.viewId > 1:
            mbr = QGraphicsRectItem(0, 0, 1, 1)
            mbr.setPen(QPen(QColor(200,25,25,255),5))
            mbr.setBrush(QColor(200,50,50,5))
            self.masterBoundingRect = mbr

        self.updateZoomLevel()

        # change border size
        self.setDefaultBorder()

    def setDefaultBorder(self): self.setBorder(2, '#CACACA')
    def setBorder(self, size, color):
        self.setStyleSheet("border: %spx solid %s" % (size, color))

    # def createTipBox(self):
    #     self.tipBox = GraphicsItems.TipBox()
    #     self.scene().addItem(self.tipBox)
    #     self.tipBox.setPos(self.scene().sceneRect().center())

    def keyPressEvent(self, evt):
        if not self.main.quickBoxBan:
            if not self.main.quickBox.hasFocus():
                self.main.quickBox.setFocus()
                self.main.quickBox.setText(evt.text())
            else:
                return super(ZoomableGraphicsView, self).keyPressEvent(evt)
        else:
            return super(ZoomableGraphicsView, self).keyPressEvent(evt)

    def focusInEvent(self, evt):
        self.main.setActiveView(self)

    def mousePressEvent(self, evt):
        self.dragging = True
        return super(ZoomableGraphicsView, self).mousePressEvent(evt)

    def mouseReleaseEvent(self, evt):
        self.dragging = False
        return super(ZoomableGraphicsView, self).mouseReleaseEvent(evt)

    def mouseMoveEvent(self, evt):
        if self.tipBox.on:
            self.tipBox.setPos(self.mapToScene(evt.pos()))
        if self.dragging:
            self.main.viewChanged.emit(self.viewId, self.mapToScene(self.rect()).boundingRect())
        return super(ZoomableGraphicsView, self).mouseMoveEvent(evt)

    def wheelEvent(self, evt):
        self.zoom(1.25**(evt.delta() / 15.0 / 8.0))
        self.main.viewChanged.emit(self.viewId, self.mapToScene(self.rect()).boundingRect())
        evt.accept()

    def updateZoomLevel(self):
        s = self.mapToScene(0.0, 0.0, 1.0, 1.0)
        self.zoomLevel = round(s.boundingRect().height(),2)
        self.main.zoomChange.emit(self.viewId, self.zoomLevel)
        #print "ZoomLevel = %s" % self.zoomLevel

    def zoom(self, factor):
        self.scale(factor, factor)
        self.updateZoomLevel()
