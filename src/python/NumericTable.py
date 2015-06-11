from qwt_common import *
from pythonwidgets import *

from YbPlot import YbPlot
class FlexGraph(YbPlot):
    def __init__(self, table):
        YbPlot.__init__(self, zoomer = True, panner = True)
        self.table = table
        #self.startTimer(1000)

        if table.model.rowCount() and table.model.columnCount():
            self.resetGraph([(0,0)])
        else:
            self.resetGraph([])

    def resetGraph(self, cells, cellsRight = []):
        self.clearAll()
        for i,cell in enumerate(cells):
            r,c = cell
            self.addLine(firstAxis = True, color=colorList[i % len(colorList)], label = '%s_%s' % (self.table.model.rLabels[r], self.table.model.cLabels[c]))
        for i,cell in enumerate(cellsRight):
            r,c = cell
            self.addLine(firstAxis = False, color=colorList[i % len(colorList)], label = '%s_%s' % (self.table.model.rLabels[r], self.table.model.cLabels[c]))
        self.cells = cells
        self.cellsRight = cellsRight
        self.updateData()
        self.updateGraph()
        
    def updateData(self):
        # load past data points
        T = self.table.model.arrayHist.shape[0]
        for t in range(len(self.x), T):
            self.x.append(t) #self.table.model.arrayHistTime[t])
            for i,cell in enumerate(self.cells):
                r,c = cell
                self.y[i].append(self.table.model.arrayHist[t, r, c])
            for i,cell in enumerate(self.cellsRight):
                r,c = cell
                self.yAxis2[i].append(self.table.model.arrayHist[t, r, c])
        self.i = T

class NumericTable(QWidget): 
    def __init__(self, columnLabels = [], rowLabels = [], digits = [], includeGraph = False, showTable = True): 
        QWidget.__init__(self) 

        #self.tv = YbTableView()
        self.tv = QTableView()
        self.tv.verticalHeader().setDefaultSectionSize(18)
        self.model = NumericModel(self, columnLabels, rowLabels, digits) 
        self.model.dataChanged.connect(self.modelUpdated)
        self.proxy = NumericModelProxy()
        self.proxy.setSourceModel(self.model)
        self.tv.setModel(self.proxy)

        self.tv.setMinimumSize(1, 1)

        # layout
        mainLayout = QVBoxLayout()
        splitter = QSplitter()
        splitter.setOrientation(Qt.Vertical)

        # upper layout includes: reset graph button, 
        # column chooser (read-only qlistwidget, row input (qspinbox), FlexGraph
        self.includeGraph = includeGraph
        if includeGraph:
            topsplitter = QSplitter()
            topsplitter.setOrientation(Qt.Horizontal)
            frm = QFrame()
            l2 = QVBoxLayout()
            self.yaxisCheck = QCheckBox('yaxis')
            self.yaxisCheck.stateChanged.connect(self.yaxisChg)
            self.maxY = QDoubleSpinBox()
            self.maxY.setDecimals(4)
            self.maxY.setRange(-999999.0, 999999.0)
            self.maxY.valueChanged.connect(self.yaxisChg)
            self.minY = QDoubleSpinBox()
            self.minY.setDecimals(4)
            self.minY.setRange(-999999.0, 999999.0)
            self.minY.valueChanged.connect(self.yaxisChg)
            l2.addWidget(self.yaxisCheck)
            l2.addWidget(self.maxY)
            l2.addWidget(self.minY)
            frm.setLayout(l2)
            self.graph = FlexGraph(self)
            topsplitter.addWidget(frm)
            topsplitter.addWidget(self.graph)
            topsplitter.setSizes([0,10])
            topsplitter.setStretchFactor(1,1)
            splitter.addWidget(topsplitter)
            splitter.setStretchFactor(0, 1)

        # toggle sort buton
        buttonLayout = QHBoxLayout()
        button = QPushButton()
        button.clicked.connect(self.toggleSort)
        button.setText('Toggle Sort')
        buttonLayout.addWidget(button)
            
        if includeGraph:
            resetHistButton = QPushButton('Reset History')
            resetHistButton.clicked.connect(self.resetHist)
            buttonLayout.addWidget(resetHistButton)

            resetGraphButton = QPushButton('Reset Graph')
            resetGraphButton.clicked.connect(self.resetGraph)
            buttonLayout.addWidget(resetGraphButton)

            freezeColsCheckBox = QCheckBox('Freeze Columns')
            freezeColsCheckBox.stateChanged.connect(self.toggleFreeze)
            freezeColsCheckBox.setSizePolicy(QSizePolicy(QSizePolicy.Fixed, QSizePolicy.Fixed))
            self.frozenCols = False
            buttonLayout.addWidget(freezeColsCheckBox)

        self.frame2 = QFrame()
        layout = QVBoxLayout()
        layout.addLayout(buttonLayout)
        if showTable:
            layout.addWidget(self.tv)
        self.frame2.setLayout(layout)
        splitter.addWidget(self.frame2)
        mainLayout.addWidget(splitter)
        self.setLayout(mainLayout)

        if isProd():
            self.setStyleSheet("NumericTable { background: %s }" % '#FF6A6A')

        self.width = self.height = 1

    def yaxisChg(self):
        if self.yaxisCheck.checkState() == Qt.Checked:
            print 'set yaxis', self.minY.value(), self.maxY.value()
            self.graph.setAxisScale(0, self.minY.value(), self.maxY.value())   
        else:
            self.graph.setAxisAutoScale(0)
    
    def modelUpdated(self):
        if self.tv.isSortingEnabled():
            if self.model.currSortCol < self.model.c:
                self.model.sort(self.model.currSortCol, self.model.sortOrder)
            else:
                self.toggleSort()

    def getModelRow(self, row):
        row  = self.proxy.mapToSource(self.proxy.index(row, 0)).row()
        return self.model.getModelRowFromTableRow(row)

    def resetModel(self, cols, rows, digits = None):
        if digits == None:
            digits = [0 for c in cols]
        self.proxy.setFilter(None)
        self.model.myreset(cols, rows, digits)
        #for i in range(self.model.r):
        #    self.tv.setRowHeight(i, 18)
        #self.resizeToContents()

    def resetHist(self):
        self.model.resetHist()

    def resetGraph(self):
        if self.includeGraph:
            if self.frozenCols:
                rows = sorted(list(set([self.getModelRow(idx.row()) for idx in self.tv.selectedIndexes()])))
                cells = []
                for r in rows:
                    for c in self.cols:
                        cells.append((r,c))
            else:
                cells = [(self.getModelRow(idx.row()), idx.column()) for idx in self.tv.selectedIndexes()]
            self.graph.resetGraph(cells)
        else:
            print 'Graph not included'

    def toggleFreeze(self, freeze):
        self.frozenCols = (freeze == Qt.Checked)
        if self.frozenCols:
            self.cols = sorted(list(set([idx.column() for idx in self.tv.selectedIndexes()])))
            print self.frozenCols, self.cols
        else:
            print 'unset freeze'
    
    def resizeToContents(self):
        width = self.tv.verticalHeader().width() + 70
        for i in range(self.model.c):
            width += self.tv.columnWidth(i) + 1
        height = self.tv.horizontalHeader().height() + 70
        for i in range(self.model.r):
            height += self.tv.rowHeight(i) + 1
        print 'Resizing to', width, 'by', height
        self.resize(width, height)
        self.width = width
        self.height = height

    def sizeHint(self):
        return QSize(self.width, self.height)

    def toggleSort(self):
        self.tv.setSortingEnabled(not self.tv.isSortingEnabled())
        self.model.emit(SIGNAL("layoutAboutToBeChanged()"))
        self.model.currSortCol = None
        self.model.emit(SIGNAL("layoutChanged()"))

    # overload this function to set the cell backgrounds
    def getBackground(self, row, col):
        return QVariant()

    # overload this function to set the cell backgrounds
    def getColumnHeaderBackground(self, col):
        return QVariant()

    # overload this function to set the cell checkstate
    def getCheckState(self, row, col):
        return QVariant()

    def getModel(self):
        return self.model


class NumericModelProxy(QSortFilterProxyModel):
    flist = None
    def setFilter(self, flist):
        self.flist = flist
        self.invalidateFilter()

    def filterAcceptsRow(self, row, source_parent):
        if self.flist == None:
            return True
        r = self.sourceModel().getModelRowFromTableRow(row)
        if r >= len(self.flist):
            return True
        return self.flist[r]

    def sort(self, column, order):
        self.sourceModel().sort(column, order)


class NumericModel(QAbstractTableModel): 
    def __init__(self, table, columnLabels, rowLabels, digits):
        super(NumericModel,self).__init__()

        self.table = table
        self.r = 0
        self.c = 0
        self.currSortCol = None
        self.myreset(columnLabels, rowLabels, digits)

    #def parent(self, index):
    #    return QModelIndex()
    
    def myreset(self, columnLabels, rowLabels, digits):
        self.cLabels = columnLabels
        self.rLabels = rowLabels

        rc = self.rowCount()
        r = len(self.rLabels)
        cc = self.columnCount()
        c = len(self.cLabels)

        #print 'reset model', r, rc, c, cc, rowLabels, columnLabels, digits
        #if r and r > rc: self.beginInsertRows(QModelIndex(), rc, r-1)
        #if c and c > cc: self.beginInsertColumns(QModelIndex(), cc, c-1)
        self.beginResetModel()

        self.r = r
        self.c = c
        self.digits = digits
        self.array = np.zeros((self.r, self.c))
        self.arrayHist = np.zeros((0,self.r,self.c))
        self.arrayHistTime = []
        #self.currSortCol = None

        #if r and r > rc: self.endInsertRows()
        #if c and c > cc: self.endInsertColumns()


        if self.currSortCol != None:
            self.sort(self.currSortCol, self.sortOrder)
        self.endResetModel()

        self.beginIndex = self.createIndex(0,0)
        self.endIndex = self.createIndex(self.r - 1, self.c - 1)
        #self.dataChanged.emit(self.beginIndex, self.endIndex)

    def resetHist(self):
        self.arrayHist = np.zeros((0,self.r,self.c))
        self.arrayHistTime = []

    def storeArraySnapshot(self):
        a = self.array.copy()
        a.shape = (1, a.shape[0], a.shape[1])
        self.arrayHist = np.vstack([self.arrayHist, a])
        # #if self.arrayHist.shape[0] > 1000:
        # #    self.arrayHist = self.arrayHist[-1000:,:,:]
        # self.arrayHistTime.append(ST.py_local_now_us() / (3600.0 * 1000000.0))
    
    def setValue(self, r, c, val):
        self.array[r, c] = float(val)

    def updated(self):
        self.storeArraySnapshot()
        self.dataChanged.emit(self.beginIndex, self.endIndex)
        #if self.currSortCol != None:
        #    self.sort(self.currSortCol, self.sortOrder)
 
    def nosort(self):
        self.currSortCol = None

    def rowCount(self, parent = QModelIndex()): 
        return self.r

    def columnCount(self, parent = QModelIndex()): 
        return self.c

    def getModelRowFromTableRow(self, row):
        #row  = self.proxy.mapToSource(QModelIndex(row, 0)).row()
        if self.currSortCol == None:
            return row
        else:
            try:
                return self.sortArray[row, self.currSortCol]
            except:
                print 'Error in NT::getModelRowFromTableRow:'
                print traceback.print_exc()
                return row

    def setDigits(self, idx, digits):
        try:
            self.digits[idx] = digits
        except KeyError:
            pass

    def data(self, index, role): 
        if not index.isValid():
            return QVariant()

        r = self.getModelRowFromTableRow(index.row())
        c = index.column()

        if role == Qt.DisplayRole:
            return pstr(float(self.array[r,c]), self.digits[c])
        elif role == Qt.TextAlignmentRole:
            return Qt.AlignRight
        elif role == Qt.BackgroundRole:
            return self.table.getBackground(r, c)
        elif role == Qt.CheckStateRole:
            return self.table.getCheckState(r, c)
        else:
            return QVariant() 

    def headerData(self, i, orientation, role):
        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            return QVariant(self.cLabels[i])
        elif orientation == Qt.Vertical and role == Qt.DisplayRole:
            if self.currSortCol != None:
                i = self.sortArray[i,self.currSortCol]
            return QVariant(self.rLabels[i])
        elif orientation == Qt.Horizontal and role == Qt.BackgroundRole:
            return self.table.getColumnHeaderBackground(i)
        return QVariant()

    def sort(self, col, order):
        self.emit(SIGNAL("layoutAboutToBeChanged()"))
        self.sortArray = np.argsort(self.array, axis=0, kind='mergesort')
        self.currSortCol = col
        self.sortOrder = order
        if order == Qt.DescendingOrder:
            self.sortArray = self.sortArray[::-1,:]
        self.emit(SIGNAL("layoutChanged()"))

if __name__ == "__main__": 
    app = QApplication(sys.argv) 
    cols = ['a','b','c']
    rows = [str(i) for i in range(5)]
    digits = [2,2,2]
    w = NumericTable(cols, rows, digits, True)
    w.resize(500,500)
    w.show() 
    m = w.getModel()

    nr = len(rows)
    nc = len(cols)
    def update():
        r = np.random.randn(nr,nc)
        for i in range(nr):
            for j in range(nc):
                m.setValue(i,j,float(i)*float(j)*r[i,j])
        m.updated()

    timer = QTimer()
    timer.timeout.connect(update)
    timer.start(500)

    sys.exit(app.exec_()) 

