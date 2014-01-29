#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:ai:

import sys
import os
import re
import subprocess
import difflib


BUFFSIZE = 1024
CLOSE_STDERR = False
reOPT = re.compile(r'^opt([0-9]+)_') # To detect -On tests
reBIN = re.compile(r'^(tzx|tap)_') # To detect tzx / tap test
PRINT_DIFF = False
VIM_DIFF = False
EXIT_CODE = 0
FILTER = r'^(([ \t]*;)|(#[ \t]*line))'

# Global tests and failed counters
COUNTER = 0
FAILED = 0
UPDATE = False  # True and test will be updated

# --------------------------------------------------

_original_root = "/src/zxb/trunk"


def isTheSameFile(fname1, fname2, ignoreLinesRE = None, 
        replaceRE = None, replaceWhat = '.', replaceWith = '.'):
    ''' Test if two files are the same.

    If ignoreLinesRE is passed, it must be a Regular Expression
    which will ignore matched lines on both files.

    If replaceRE is passed, al lines matching RE (string) will perform
    a string substitution of A into B. This if done *AFTER* ignoreLinesRE.
    '''
    if fname1 == fname2:
        return True

    if not os.path.exists(fname1) and not os.path.exists(fname2):
        return True

    if not os.path.exists(fname1) or not os.path.exists(fname2):
        return False

    f1 = open(fname1, 'rb')
    f2 = open(fname2, 'rb')

    r1 = f1.readlines()
    r2 = f2.readlines()

    if ignoreLinesRE is not None:
        r = re.compile(ignoreLinesRE)
        r1 = [x for x in r1 if not r.search(x)]
        r2 = [x for x in r2 if not r.search(x)]

    if replaceRE is not None and replaceWhat and replaceWith is not None:
        r = re.compile(replaceRE)
        r1 = [x.replace(replaceWhat, replaceWith, 1) if r.search(x) else x for x in r1]
        r2 = [x.replace(replaceWhat, replaceWith, 1) if r.search(x) else x for x in r2]
  
    result = (r1 == r2)

    f1.close()
    f2.close()

    if PRINT_DIFF and not result:
        if VIM_DIFF:
            systemExec('gvimdiff %s %s' % (fname1, fname2))
        else:
            for line in difflib.unified_diff(r1, r2, fname1, fname2):
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



def testBAS(fname, filter_ = None):
    ''' filter_ will be ignored for binary (tzx, tap, etc) files
    '''
    prep = ' -e /dev/null' if CLOSE_STDERR else ''
    OPTIONS = ''

    match = reOPT.match(getName(fname))
    if match:
        OPTIONS = ' -O' + match.groups()[0] + ' '

    match = reBIN.match(getName(fname))
    if match and match.groups()[0].lower() in ('tzx', 'tap'):
        ext = match.groups()[0].lower()
        tfname = os.path.join('tmp', getName(fname) + os.extsep + ext)
        OPTIONS += ('--%s ' % ext) + fname + ' -o ' + tfname + prep
        filter_ = None
    else:
        ext = 'asm'
        if not UPDATE:
            tfname = 'test' + fname + os.extsep + ext
        else:
            tfname = getName(fname) + os.extsep + ext
        OPTIONS += '--asm ' + fname + ' -o ' + tfname + prep

    cmdline = './zxb.py ' + OPTIONS 
    if systemExec(cmdline):
        try:
            if UPDATE:
                raise
            os.unlink(tfname)
        except OSError:
            pass

    if UPDATE:
        return

    okfile = getName(fname) + os.extsep + ext
    result = isTheSameFile(okfile, tfname, filter_)

    try:
        os.unlink(tfname)
    except OSError:
        pass

    return result



def testPREPRO(fname, pattern_ = None):
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
    result = isTheSameFile(okfile, tfname, replaceRE = pattern_,
             replaceWhat = ZXBASIC_ROOT, replaceWith = _original_root)

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
            result = testBAS(fname, filter_ = FILTER)
        elif ext == 'bi':
            result = testPREPRO(fname, pattern_ = FILTER)
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



def upgradeTest(fileList, f3diff):
    ''' Run against the list of files, and a 3er file containing the diff.
    If the diff between file1 and file2 are the same as file3, then the 
    .asm file is patched.
    '''
    def normalizeDiff(diff):
        reHEADER = re.compile(r'[-+]{3}')
        while diff and reHEADER.match(diff[0]):
            diff = diff[1:]

        first = True
        reHUNK = re.compile(r'@@ \-(\d+)(,\d)? \+(\d+)(,\d)? @@')
        for i in range(len(diff)):
            line = diff[i]
            match = reHUNK.match(line)
            if match:
                g = match.groups()
                g = [x if x is not None else '' for x in g]
                if first:
                    first = False
                    O1 = int(g[0])
                    O2 = int(g[2])

                diff[i] = "@@ -%(a)s%(b)s +%(c)s%(d)s\n" % \
                    { 'a': int(g[0]) - O1, 'b': g[1], 
                      'c': int(g[2]) - O2, 'd': g[3] }
        
        return diff


    fdiff = open(f3diff).readlines()
    fdiff = normalizeDiff(fdiff)
    prep = ' -e /dev/null' if CLOSE_STDERR else ''

    for fname in fileList:
        ext = getExtension(fname)
        if ext != 'bas':
            continue

        if testBAS(fname):
            continue

        fname0 = getName(fname)
        fname1 = fname0 + os.extsep + 'asm'
        tfname = 'test' + fname0 + os.extsep + 'asm'

        OPTIONS = ''
        match = reOPT.match(getName(fname))
        if match:
            OPTIONS = ' -O' + match.groups()[0] + ' '

        if systemExec('./zxb.py --asm ' + OPTIONS + fname + ' -o ' + tfname + prep):
            try:
                os.unlink(tfname)
            except OSError:
                pass

            continue

        s1 = open(fname1, 'rt').readlines()
        s2 = open(tfname, 'rt').readlines()
        lines = [line for line in difflib.unified_diff(s1, s2, fname1, tfname)]
        lines = normalizeDiff(lines)

        if lines != fdiff:
            os.unlink(tfname)
            continue # Not the same diff
        
        os.unlink(fname1)
        os.rename(tfname, fname1)
        print "\rTest: %s (%s) updated" % (fname, fname1)

    

def help_():
    print """{0}\n
Usage:
    {0} [params] <filename*>

Params:
    -d:  Show diffs
    -vd: Show diffs visually (using vimdiff)
    -u:  Update tests
    -U:  Update test

Example:
    {0} a.bas b.bas      # Cheks for test a.bas, b.bas 
    {0} -vd *.bas        # Checks for any *.bas test and displays diffs
    {0} -u a*.bas b.diff # Updates all a*.bas tests if the b.diff matches
    {0} -U b*.bas        # Updates b test with the output of the current compiler 
    """.format(sys.argv[0])
    sys.exit(2)


def check_arg(i):
    if len(sys.argv) <= i:
        help_()

    
if __name__ == '__main__':
    ZXBASIC_ROOT = os.path.abspath('../..')    

    i = 1
    check_arg(i)

    CLOSE_STDERR = True
    if sys.argv[i] in ('-d', '-vd'):
        PRINT_DIFF = True
        VIM_DIFF = (sys.argv[1] == '-vd')
        i += 1

    check_arg(i)
    if sys.argv[i] == '-u':
        i += 1
        check_arg(i + 1)
        f3diff = sys.argv[i]
        fileList = sys.argv[i + 1:]
        upgradeTest(fileList, f3diff)
        sys.exit(EXIT_CODE)
    elif sys.argv[1] == '-U':
        i +=1
        UPDATE = True

    check_arg(i)
    testFiles(sys.argv[i:])
    print "Total: %i, Failed: %i (%3.2f%%)" % (COUNTER, FAILED, 100.0 * FAILED / float(COUNTER))

    sys.exit(EXIT_CODE)
        

