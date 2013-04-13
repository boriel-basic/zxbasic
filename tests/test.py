#!/usr/bin/env python
# vim:ts=4:et:ai:

import sys
import os
import re
import StringIO
import subprocess
import difflib


BUFFSIZE = 1024
CLOSE_STDERR = False
reOPT = re.compile(r'^opt([0-9]+)_')
PRINT_DIFF = False
VIM_DIFF = False
EXIT_CODE = 0

# Global tests and failed counters
COUNTER = 0
FAILED = 0




def isTheSameFile(fname1, fname2):
    if fname1 == fname2:
        return True

    if not os.path.exists(fname1) and not os.path.exists(fname2):
        return True

    try:
        f1 = open(fname1, 'rb')
        f2 = open(fname2, 'rb')
    except:
        if PRINT_DIFF:
            try:
                f1 = open(fname1, 'rb')
                print fname2 + ' does not exists'
            except:
                print fname1 + ' does not exists'

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

    if PRINT_DIFF and not result:
        if VIM_DIFF:
            systemExec('gvimdiff %s %s' % (fname1, fname2))
        else:
            s1 = open(fname1, 'rt').readlines()
            s2 = open(fname2, 'rt').readlines()
            for line in difflib.unified_diff(s1, s2, fname1, fname2):
                sys.stdout.write(line)
    
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
    prep = ' 2> /dev/null' if CLOSE_STDERR else ''
    OPTIONS = ''
    match = reOPT.match(getName(fname))
    if match:
        OPTIONS = ' -O' + match.groups()[0] + ' '
        
    if systemExec('./zxbpp.py ' + OPTIONS + fname + ' >' + tfname + prep):
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
    ''' Run tests for the given file extension
    '''
    global EXIT_CODE, COUNTER, FAILED

    COUNTER = 0

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

        COUNTER += 1
        print ("%4i " % COUNTER) + fname + ':',

        if result:
            sys.stdout.write('ok        \r')
            sys.stdout.flush()
        elif result is None:
            print '?\r',
        else:
            FAILED += 1
            EXIT_CODE = 1
            print 'FAIL'
    
    
if __name__ == '__main__':
    CLOSE_STDERR = True
    if sys.argv[1] == '-d':
        PRINT_DIFF = True

    if sys.argv[1] == '-vd':
        PRINT_DIFF = True
        VIM_DIFF = True
        
    testFiles(sys.argv[1 + int(PRINT_DIFF):])
    print "Total: %i, Failed: %i (%3.2f%%)" % (COUNTER, FAILED, 100.0 * FAILED / float(COUNTER))

    sys.exit(EXIT_CODE)
        

