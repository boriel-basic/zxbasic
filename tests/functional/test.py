#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:ai:

import sys
import os
import re
import argparse
import subprocess
import difflib


CLOSE_STDERR = False
reOPT = re.compile(r'^opt([0-9]+)_')  # To detect -On tests
reBIN = re.compile(r'^(tzx|tap)_')  # To detect tzx / tap test

EXIT_CODE = 0
FILTER = r'^(([ \t]*;)|(#[ \t]*line))'

# Global tests and failed counters
COUNTER = 0
FAILED = 0
ZXBASIC_ROOT = os.path.abspath(os.path.join(
    os.path.dirname(os.path.abspath(__file__)), os.path.pardir, os.path.pardir
))
ZXB = os.path.join(ZXBASIC_ROOT, 'zxb.py')
ZXBASM = os.path.join(ZXBASIC_ROOT, 'zxbasm.py')
ZXBPP = os.path.join(ZXBASIC_ROOT, 'zxbpp.py')

_original_root = "/src/zxb/trunk"
sys.path.append(ZXBASIC_ROOT)

# global FLAGS
PRINT_DIFF = False  # Will show diff on test failure
VIM_DIFF = False  # Will show visual diff using (g?)vimdiff on test failure
UPDATE = False  # True and test will be updated on failure
FOUT = sys.stdout  # Output file. By default stdout but can be captured changing this


def get_file_lines(filename, ignore_regexp=None, replace_regexp=None,
                   replace_what='.', replace_with='.'):
    """ Opens source file <filename> and load its lines,
    discarding those not important for comparison.
    """
    from api.utils import open_file
    with open_file(filename, 'rt', 'utf-8') as f:
        lines = [x for x in f]

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
    return split[-1] if len(split) > 1 else None


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

    cmdline = '{0} {1}'.format(ZXB, options)
    return cmdline, tfname, ext


def testASM(fname):
    tfname = 'test' + fname + os.extsep + 'bin'
    prep = ' -e /dev/null' if CLOSE_STDERR else ''
    okfile = getName(fname) + os.extsep + 'bin'

    if UPDATE:
        tfname = okfile

    if systemExec('{0} {1} -o {2}{3}'.format(ZXBASM, fname, tfname, prep)):
        try:
            os.unlink(tfname)
        except OSError:
            pass

    result = is_same_file(okfile, tfname, is_binary=True)
    if UPDATE:
        return

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
    okfile = getName(fname) + os.extsep + 'out'
    OPTIONS = ''
    match = reOPT.match(getName(fname))
    if match:
        OPTIONS = '-O' + match.groups()[0]

    if UPDATE:
        tfname = okfile

    if systemExec('{0} {1} {2} > {3}{4}'.format(ZXBPP, OPTIONS, fname, tfname, prep)):
        try:
            os.unlink(tfname)
        except OSError:
            pass

    if UPDATE:
        return

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


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Test compiler output against source code samples')
    parser.add_argument('-d', '--show-diff', action='store_true', help='Shows output difference on failure')
    parser.add_argument('-v', '--show-visual-diff', action='store_true', help='Shows visual difference using vimdiff '
                                                                              'upon failure')
    parser.add_argument('-u', '--update', type=str, default=None, help='Updates all *.bas test if the UPDATE diff'
                                                                       ' matches')
    parser.add_argument('-U', '--force-update', action='store_true', help='Updates all failed test with the new output')
    parser.add_argument('FILES', nargs='+', type=str, help='List of files to be processed')

    args = parser.parse_args()

    CLOSE_STDERR = True

    if args.update:
        upgradeTest(args.FILES, args.update)
        exit(EXIT_CODE)

    PRINT_DIFF = args.show_diff
    VIM_DIFF = args.show_visual_diff
    UPDATE = args.force_update
    testFiles(args.FILES)

    if COUNTER:
        print("Total: %i, Failed: %i (%3.2f%%)" % (COUNTER, FAILED, 100.0 * FAILED / float(COUNTER)))
    else:
        print('No tests found')
        EXIT_CODE = 1

    exit(EXIT_CODE)
