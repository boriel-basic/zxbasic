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
reOPT = re.compile(r'^opt([0-9]+)_')  # To detect -On tests
reBIN = re.compile(r'^(tzx|tap)_')  # To detect tzx / tap test
PRINT_DIFF = False
VIM_DIFF = False
EXIT_CODE = 0
FILTER = r'^(([ \t]*;)|(#[ \t]*line))'

# Global tests and failed counters
COUNTER = 0
FAILED = 0
UPDATE = False  # True and test will be updated
FOUT = sys.stdout  # Output file

# --------------------------------------------------

_original_root = "/src/zxb/trunk"


def get_file_lines(filename, ignore_regexp=None, replace_regexp=None,
                   replace_what='.', replace_with='.'):
    """ Opens source file <filename> and load its line,
    discarding those not important for comparison.
    """
    with open(filename, 'rb') as f:
        lines = [x.decode('utf-8') for x in f.readlines()]

        if ignore_regexp is not None:
            r = re.compile(ignore_regexp)
            lines = [x for x in lines if not r.search(x)]

        if replace_regexp is not None and replace_what and replace_with is not None:
            r = re.compile(replace_regexp)
            lines = [x.replace(replace_what, replace_with, 1) if r.search(x) else x for x in lines]

    return lines


def is_same_file(fname1, fname2, ignore_regexp=None,
                 replace_regexp=None, replace_what='.', replace_with='.', diff=None, is_binary=False):
    """ Test if two files are the same.

    If ignore_regexp is passed, it must be a Regular Expression
    which will ignore matched lines on both files.

    If replace_regexp is passed, all lines matching RE (string) will perform
    a string substitution of A into B. This if done *AFTER* ignoreLinesRE.
    """
    if fname1 == fname2:
        return True

    if not os.path.exists(fname1) and not os.path.exists(fname2):
        return True

    if not os.path.exists(fname1) or not os.path.exists(fname2):
        return False

    if is_binary:
        return open(fname1, 'rb').read() == open(fname2, 'rb').read()

    r1 = get_file_lines(fname1, ignore_regexp, replace_regexp, replace_what, replace_with)
    r2 = get_file_lines(fname2, ignore_regexp, replace_regexp, replace_what, replace_with)
    result = (r1 == r2)

    if not result:
        if diff is None:
            diff = []
        diff.extend(difflib.unified_diff(r1, r2, fname1, fname2))

    if PRINT_DIFF and not result:
        if VIM_DIFF:
            systemExec('gvimdiff %s %s' % (fname1, fname2))
        else:
            sys.stdout.write(''.join(diff))

    return result


def systemExec(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT):
    result = subprocess.Popen(command, bufsize=-1, shell=True,
                              stdout=stdout, stderr=stderr)
    exit_code = result.wait()
    FOUT.write(result.stdout.read().decode('utf-8'))
    return exit_code


def getExtension(fname):
    """ Returns filename extension.
    Returns None if no extension.
    """
    split = os.path.basename(fname).split(os.extsep)
    if len(split) > 1:
        return split[-1]

    return None


def getName(fname):
    """ Returns filename (without extension)
    """
    basename = os.path.basename(fname)
    if getExtension(basename) is None:
        return basename

    return basename.split(os.extsep)[0]


def _get_testbas_cmdline(fname):
    """ Generates a command line string to be executed to
    get the .asm test file from a .bas one.
    :param str fname: .bas filename source file
    :rtype: tuple
    :return: a tuple containing (in this order),
            - the command line to be used
            - the test .asm file that will be generated
            - the extension of the file (normally .asm)
    """
    prep = ' -e /dev/null' if CLOSE_STDERR else ''
    options = ' -O1 '

    match = reOPT.match(getName(fname))
    if match:
        options = ' -O' + match.groups()[0] + ' '

    match = reBIN.match(getName(fname))
    if match and match.groups()[0].lower() in ('tzx', 'tap'):
        ext = match.groups()[0].lower()
        tfname = os.path.join('tmp', getName(fname) + os.extsep + ext)
        options += ('--%s ' % ext) + fname + ' -o ' + tfname + prep
    else:
        ext = 'asm'
        if not UPDATE:
            tfname = 'test' + fname + os.extsep + ext
        else:
            tfname = getName(fname) + os.extsep + ext
        options += '--asm ' + fname + ' -o ' + tfname + prep

    cmdline = './zxb.py ' + options
    return cmdline, tfname, ext


def testASM(fname):
    tfname = 'test' + fname + os.extsep + 'bin'
    prep = ' -e /dev/null' if CLOSE_STDERR else ''

    if systemExec('./zxbasm.py ' + fname + ' -o ' + tfname + prep):
        try:
            os.unlink(tfname)
        except OSError:
            pass

    okfile = getName(fname) + os.extsep + 'bin'
    result = is_same_file(okfile, tfname, is_binary=True)
    try:
        os.unlink(tfname)
    except OSError:
        pass

    return result


def testBAS(fname, filter_=None):
    """ filter_ will be ignored for binary (tzx, tap, etc) files
    """
    cmdline, tfname, ext = _get_testbas_cmdline(fname)
    if systemExec(cmdline):
        try:
            os.unlink(tfname)
        except OSError:
            pass

    if UPDATE:
        return

    okfile = getName(fname) + os.extsep + ext
    result = is_same_file(okfile, tfname, filter_, is_binary=reBIN.match(fname) is not None)

    try:
        os.unlink(tfname)
    except OSError:
        pass

    return result


def testPREPRO(fname, pattern_=None):
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
    result = is_same_file(okfile, tfname, replace_regexp=pattern_,
                          replace_what=ZXBASIC_ROOT, replace_with=_original_root)
    try:
        os.unlink(tfname)
    except OSError:
        pass

    return result


def testFiles(file_list):
    """ Run tests for the given file extension
    """
    global EXIT_CODE, COUNTER, FAILED
    COUNTER = 0

    for fname in file_list:
        ext = getExtension(fname)
        if ext == 'asm':
            if os.path.exists(getName(fname) + os.extsep + 'bas'):
                continue  # Ignore asm files which have a .bas since they're test results
            result = testASM(fname)
        elif ext == 'bas':
            result = testBAS(fname, filter_=FILTER)
        elif ext == 'bi':
            result = testPREPRO(fname, pattern_=FILTER)
        else:
            result = None

        COUNTER += 1
        FOUT.write(("%4i " % COUNTER) + fname + ':')

        if result:
            FOUT.write('ok        \r')
            FOUT.flush()
        elif result is None:
            FOUT.write('?\r')
        else:
            FAILED += 1
            EXIT_CODE = 1
            FOUT.write('FAIL\n')


def upgradeTest(fileList, f3diff):
    """ Run against the list of files, and a 3rd file containing the diff.
    If the diff between file1 and file2 are the same as file3, then the 
    .asm file is patched.
    """

    def normalizeDiff(diff):
        diff = [x.strip(' \t') for x in diff]

        reHEADER = re.compile(r'[-+]{3}')
        while diff and reHEADER.match(diff[0]):
            diff = diff[1:]

        first = True
        reHUNK = re.compile(r'@@ [-+](\d+)(,\d+)? [-+](\d+)(,\d+)? @@')
        for i in range(len(diff)):
            line = diff[i]
            if line[:7] in ('-#line ', '+#line '):
                diff[i] = ''
                continue

            match = reHUNK.match(line)
            if match:
                g = match.groups()
                g = [x if x is not None else '' for x in g]
                if first:
                    first = False
                    O1 = int(g[0])
                    O2 = int(g[2])

                diff[i] = "@@ -%(a)s%(b)s +%(c)s%(d)s\n" % \
                          {'a': int(g[0]) - O1, 'b': g[1], 'c': int(g[2]) - O2, 'd': g[3]}

        return diff

    fdiff = open(f3diff).readlines()
    fdiff = normalizeDiff(fdiff)

    for fname in fileList:
        ext = getExtension(fname)
        if ext != 'bas':
            continue

        if testBAS(fname):
            continue

        fname0 = getName(fname)
        fname1 = fname0 + os.extsep + 'asm'
        cmdline, tfname, ext = _get_testbas_cmdline(fname)
        if systemExec(cmdline):
            try:
                os.unlink(tfname)
            except OSError:
                pass
            continue

        lines = []
        is_same_file(fname1, tfname, ignore_regexp=FILTER, diff=lines)
        lines = normalizeDiff(lines)

        if lines != fdiff:
            for x, y in zip(lines, fdiff):
                x = x.strip()
                y = y.strip()
                c = '=' if x == y else '!'
                print('"%s"%s"%s"' % (x.strip(), c, y.strip()))
            os.unlink(tfname)
            continue  # Not the same diff

        os.unlink(fname1)
        os.rename(tfname, fname1)
        print("\rTest: %s (%s) updated" % (fname, fname1))


def help_():
    print("""{0}\n
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
    {0} -u b.diff a*.bas # Updates all a*.bas tests if the b.diff matches
    {0} -U b*.bas        # Updates b test with the output of the current compiler 
    """.format(sys.argv[0]))
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
        i += 1
        UPDATE = True

    check_arg(i)
    testFiles(sys.argv[i:])
    print("Total: %i, Failed: %i (%3.2f%%)" % (COUNTER, FAILED, 100.0 * FAILED / float(COUNTER)))

    sys.exit(EXIT_CODE)
