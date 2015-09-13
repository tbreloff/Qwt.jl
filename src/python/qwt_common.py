import sys,os,datetime
import locale
try:
    # TODO: something more general
    locale.setlocale(locale.LC_ALL, 'en_US')
except:
    pass

def pstr(val, digits = 0):
    if digits == None:
        if type(val) == int:
            return pstr(val)
        elif type(val) == float:
            if abs(val) > 999.0: return pstr(val)
            elif abs(val) > 0.5: return pstr(val,2)
            else: return pstr(val,5)
        else:
            return str(val)
    return locale.format('%%0.%df' % digits, val, grouping=True)


def getTime(fmt = '%H:%M:%S.%f'): return datetime.datetime.now().strftime(fmt)
def getShortTime(): return getTime('%H:%M:%S')
def getDate(): return getTime('%Y-%m-%d')
def getDateTime(): return getTime('%Y-%m-%d_%H-%M-%S')



