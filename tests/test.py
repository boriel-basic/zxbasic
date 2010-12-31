#!/usr/bin/env python
# vim:ts=4:et:ai:

import sys
import os
import re
import StringIO
import subprocess


BUFFSIZE = 1024
CLOSE_STDERR = False
reOPT = re.compile(r'^opt([0-9]+)_')



def isTheSameFile(fname1, fname2):
    if fname1 == fname2:
        return True

    if not os.path.exists(fname1) and not os.path.exists(fname2):
        return True

    try:
        f1 = open(fname1, 'rb')
        f2 = open(fname2, 'rb')
    except:
        return False

    r1 = f1.read(BUFFSIZE)
    r2 = f2.read(BUFFSIZE)
   
    while r1 == r2:
        if r1 == "" or r2 == "":
            break

        r1 = f1.read(BUFFSIZE)
        r2 = f2.read(BUFFSIZE)

    result = (r1 == r2)

    f1.close()
    f2.close()

    return result



def systemExec(command, stdout = subprocess.PIPE, stderr = subprocess.STDOUT):
    result = subprocess.Popen(command, bufsize = -1, shell = True,
        stdout = stdout, stderr = stderr)

    exit_code = result.wait()
    print result.stdout.read(), 

    return exit_code



def getExtension(fname):
    ''' Returns filename extension.
    Returns None if no extension.
    '''
    split = os.path.basename(fname).split(os.extsep)
    if len(split) > 1:
        return split[-1]
    
    return None



def getName(fname):
    ''' Returns filename (without extension)
    '''
    basename = os.path.basename(fname)
    if getExtension(basename) is None:
        return basename

    return basename.split(os.extsep)[0]
    


def testASM(fname):
    tfname = 'test' + fname + os.extsep + 'bin'
    prep = ' -e /dev/null' if CLOSE_STDERR else ''

    if systemExec('./zxbasm.py ' + fname + ' -o ' + tfname + prep):
        try:
            os.unlink(tfname)
        except OSError:
            pass

    okfile = getName(fname) + os.extsep + 'bin'
    result = isTheSameFile(okfile, tfname)
    try:
        os.unlink(tfname)
    except OSError:
        pass

    return result



def testBAS(fname):
    tfname = 'test' + fname + os.extsep + 'asm'
    prep = ' -e /dev/null' if CLOSE_STDERR else ''
    OPTIONS = ''
    match = reOPT.match(getName(fname))
    if match:
        OPTIONS = ' -O' + match.groups()[0] + ' '
        
    if systemExec('./zxb.py --asm ' + OPTIONS + fname + ' -o ' + tfname + prep):
        try:
            os.unlink(tfname)
        except OSError:
            pass

    okfile = getName(fname) + os.extsep + 'asm'
    result = isTheSameFile(okfile, tfname)

    try:
        os.unlink(tfname)
    except OSError:
        pass

    return result



def testPREPRO(fname):
    tfname = 'test' + fname + os.extsep + 'out'
    prep = ' -e /dev/null' if CLOSE_STDERR else ''
    OPTIONS = ''
    match = reOPT.match(getName(fname))
    if match:
        OPTIONS = ' -O' + match.groups()[0] + ' '
        
    if systemExec('./zxbpp.py ' + OPTIONS + fname + ' 2>/dev/null 1>' + tfname + prep):
        try:
            os.unlink(tfname)
        except OSError:
            pass

    okfile = getName(fname) + os.extsep + 'out'
    result = isTheSameFile(okfile, tfname)

    try:
        os.unlink(tfname)
    except OSError:
        pass

    return result



def testFiles(fileList):
    for fname in fileList:
        ext = getExtension(fname)
        if ext == 'asm':
            if os.path.exists(getName(fname) + os.extsep + 'bas'):
                continue # Ignore asm files which have a .bas since they're test results

            result = testASM(fname)
        elif ext == 'bas':
            result = testBAS(fname)
        elif ext == 'bi':
            result = testPREPRO(fname)
        else:
            result = None

        print fname + ':',

        if result:
            print 'ok'
        elif result is None:
            print '?'
        else:
            print 'FAIL'
    
    
if __name__ == '__main__':
    CLOSE_STDERR = True
    testFiles(sys.argv[1:])
        

