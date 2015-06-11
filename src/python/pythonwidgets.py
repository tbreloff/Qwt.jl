from qwt_common import *
from PyQt4.QtCore import * 
from PyQt4.QtGui import * 
import PyQt4.Qwt5 as Qwt

import signal
def sigint_handler(*args):
    sys.stderr.write('\r')
    QApplication.quit()
signal.signal(signal.SIGINT, sigint_handler)

colorList = [Qt.black, Qt.red, Qt.green, Qt.blue, Qt.cyan, Qt.magenta,
        Qt.darkRed, Qt.darkGreen, Qt.darkBlue, Qt.darkCyan, Qt.darkMagenta]
    
class TextTable:
    def __init__(self, widths, rjust = None, headers = None):
        self.widths = widths
        if rjust is None:
            self.rjust = [True for x in widths]
        else:
            self.rjust = rjust
        self.headers = headers
        self.numCols = len(widths)
        if len(self.rjust) != self.numCols or (headers != None and len(headers) != self.numCols):
            raise 'Error in TextTable initialization. %s %s %s' % (str(widths), str(self.rjust), str(headers))

    def get(self, data):
        final = ''

        if self.headers != None:
            data = [self.headers] + data

        lines = []
        for row in data:
            thisRow = ''
            for c,cell in enumerate(row):
                s = str(cell)
                if self.rjust[c]:
                    thisRow += s.rjust(self.widths[c])
                else:
                    thisRow += s.ljust(self.widths[c])
                thisRow += ' '
            lines.append(thisRow)
            #final += '\n'
        return '\n'.join(lines), max([len(l) for l in lines])

class SimpleText(QTextEdit):
    def __init__(self, widths, rjust = None, headers = None):
        QTextEdit.__init__(self)
        self.setReadOnly(True)
        self.setFontSize(12)
        self.setSizePolicy(QSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding))
        #self.setVerticalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.table = TextTable(widths, rjust, headers)

    def update(self, data):
        text, totalWidth = self.table.get(data)
        self.setText(text)
        self.setMinimumWidth(totalWidth * self.widthPerChar + 30)
        self.setMinimumHeight(min(300, len(data) * self.heightPerChar + 20))

    def setFontSize(self, pt):
        font = QFont('Courier', pt)
        self.setCurrentFont(font)
        fm = QFontMetrics(font)
        self.widthPerChar = fm.width('a')
        self.heightPerChar = fm.height()

class LayoutSplitter(QSplitter):
    def __init__(self, layouts, o = Qt.Vertical):
        QSplitter.__init__(self, o)
        for layout in layouts:
            frame = QFrame()
            frame.setLayout(layout)
            self.addWidget(frame)

class YbLabel(QLabel):
    def __init__(self, txt):
        super(YbLabel, self).__init__(txt)
        #self.setSizePolicy(QSizePolicy.Minimum, QSizePolicy.Minimum)
        self.setSizePolicy(QSizePolicy.Fixed, QSizePolicy.Fixed)
        self.setAlignment(Qt.AlignRight | Qt.AlignVCenter)

class YbListInput(QWidget):
    def __init__(self, fn, buttonText, buttonClickedFunction):
        QWidget.__init__(self)
        
        self.fn = fn
        self.text = QTextEdit()
        try:
            self.text.setText(open(self.fn).read())
        except:
            pass
        self.text.textChanged.connect(self.chg)
        self.button = QPushButton('Set: %s' % buttonText)
        self.button.clicked.connect(buttonClickedFunction)

        for x in [self.text,self.button,self]:
            x.setMinimumWidth(50)

        layout = QVBoxLayout()
        layout.addWidget(self.text)
        layout.addWidget(self.button)
        self.setLayout(layout)

        self.chg()

    def chg(self):
        #self.text.setTextBackgroundColor(QColor(Qt.lightGray))
        self.button.setStyleSheet("QPushButton { background-color: darkGray }")
        
    def parseText(self, minColumns = 2):
        #print self.text.toPlainText()
        res = []
        try:
            lines = [l.upper() for l in str(self.text.toPlainText()).split('\n')]
            lines.sort()
            linesout = []
            for l in lines:
                tmp = l.strip().split()
                if len(tmp) >= minColumns:
                    res.append(tmp)
                    linesout.append(l)
                else:
                    print 'Not enough columns: line "%s"' % l
            f = open(self.fn, 'w')
            f.write('\n'.join(linesout))
            f.close()
            self.text.setText('\n'.join(linesout))
        except Exception, e:
            print 'Error: %s' % e
        #self.text.setTextBackgroundColor(QColor(Qt.white))
        self.button.setStyleSheet("QPushButton { background-color: lightGray }")
        return res

class SelectOnFocusLineEdit(QLineEdit):
    #def __init__(self, text, parent=None):
    #    super(SelectOnFocusLineEdit, self).__init__(text, parent)
    #    self.selectOnMousePress = False

    #def focusInEvent(self, evt):
    #    QLineEdit.focusInEvent(self, evt)   
    #    self.setFocus()
    #    self.selectAll()
    #    self.selectOnMousePress = True

    def mousePressEvent(self, evt):
        self.clear()
        QLineEdit.mousePressEvent(self, evt)
        #if self.selectOnMousePress:
        #    #self.selectAll()
        #    self.selectOnMousePress = False


# takes a nested list and returns a layered layout
def buildLayout(widgets, horizontal = False, splitters = []):
    layout = QHBoxLayout() if horizontal else QVBoxLayout()
    if len(widgets) > 0 and widgets[-1] == 'splitter':
        splitter = QSplitter(Qt.Horizontal if horizontal else Qt.Vertical)
        for w in widgets[:-1]:
            #print '!!!!!!!!!!!', w, type(w)
            if type(w) == list:
                frame = QFrame()
                frame.setLayout(buildLayout(w, not horizontal, splitters))
                splitter.addWidget(frame)
            elif type(w) in [QHBoxLayout, QVBoxLayout, QFormLayout, QGridLayout, QLayout]:
                frame = QFrame()
                frame.setLayout(w)
                splitter.addWidget(frame)
            else:
                splitter.addWidget(w)
        layout.addWidget(splitter)
        splitters.append(splitter)
    else:
        for w in widgets:
            #print '!!!!!!!!!xx', w, type(w)
            if type(w) == list:
                layout.addLayout(buildLayout(w, not horizontal, splitters))
            elif type(w) in [QHBoxLayout, QVBoxLayout, QFormLayout, QGridLayout, QLayout]:
                layout.addLayout(w)
            else:
                layout.addWidget(w)
    return layout


def pdb(debug = False):
    print traceback.print_exc()
    if debug:
        from PyQt4.QtCore import pyqtRemoveInputHook
        import pdb
        pyqtRemoveInputHook()
        pdb.set_trace()
