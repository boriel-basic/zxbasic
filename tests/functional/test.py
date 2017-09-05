#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:ai:

import sys
import os
import re
import argparse
import subprocess
import difflib
import tempfile


reOPT = re.compile(r'^opt([0-9]+)_')  # To detect -On tests
reBIN = re.compile(r'^(tzx|tap)_')  # To detect tzx / tap test

EXIT_CODE = 0
FILTER = r'^(([ \t]*;)|(#[ \t]*line))'

# Global tests and failed counters
COUNTER = 0
FAILED = 0
CURR_DIR = os.path.abspath(os.path.dirname(os.path.abspath(__file__)))
ZXBASIC_ROOT = os.path.abspath(os.path.join(CURR_DIR, os.path.pardir, os.path.pardir))
ZXB = os.path.join(ZXBASIC_ROOT, 'zxb.py')
ZXBASM = os.path.join(ZXBASIC_ROOT, 'zxbasm.py')
ZXBPP = os.path.join(ZXBASIC_ROOT, 'zxbpp.py')

_original_root = "/src/zxb/trunk"

sys.path.append(ZXBASIC_ROOT)  # TODO: consider moving test.py to another place to avoid this

# Now we can import the modules from the root
import zxb  # noqa
import zxbasm  # noqa
import zxbpp  # noqa

# global FLAGS
CLOSE_STDERR = False  # Whether to show compiler error or not (usually not when doing tests)
PRINT_DIFF = False  # Will show diff on test failure
VIM_DIFF = False  # Will show visual diff using (g?)vimdiff on test failure
UPDATE = False  # True and test will be updated on failure
FOUT = sys.stdout  # Output file. By default stdout but can be captured changing this
TEMP_DIR = None
QUIET = False  # True so suppress output (useful for testing)
STDERR = '/dev/stderr'
INLINE = True  # Set to false to use system Shell


class TempTestFile(object):
    """ Uses a python guard context to ensure file deletion.
    Executes a system command which creates a temporary file and
    ensures file deletion upon return.
    """
    def __init__(self, func, fname, keep_file=False):
        """ Initializes the context. The flag dont_remove will only be taken into account
        if the System command execution was successful (returns 0)
        :param syscmd: System command to execute
        :param fname: Temporary file to remove
        :param keep_file: Don't delete the file on command success (useful for debug or updating)
        """
        self.func = func
        self.fname = fname
        self.keep_file = keep_file
        self.error_level = None

    def __enter__(self):
        try:
            self.error_level = self.func()
        finally:
            if self.error_level is None:
                try:
                    os.unlink(self.fname)
                except OSError:
                    pass

        return self.error_level

    def __exit__(self, type_, value, traceback):
        if self.error_level or not self.keep_file:  # command failure or remove file?
            try:
                os.unlink(self.fname)
            except OSError:
                pass  # Ok. It might be that the wasn't created


def _error(msg, exit_code=None):
    """ Shows an error msg to sys.stderr and optionally
    exits if exit code is not None
    """
    sys.stderr.write("%s\n" % msg)
    if exit_code is not None:
        exit(exit_code)


def _msg(msg, force=False):
    """ Shows a msg to the FOUT output if not in QUIET mode or force == True
    """
    if not QUIET or force:
        FOUT.write(msg)


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


def _get_testbas_options(fname):
    """ Generates a command line string to be executed to
    get the .asm test file from a .bas one.
    :param str fname: .bas filename source file
    :rtype: tuple
    :return: a tuple containing (in this order),
            - the command line to be used
            - the test .asm file that will be generated
            - the extension of the file (normally .asm)
    """
    prep = ['-e', '/dev/null'] if CLOSE_STDERR else ['-e', STDERR]
    options = ['-O1']

    match = reOPT.match(getName(fname))
    if match:
        options = ['-O' + match.groups()[0]]

    match = reBIN.match(getName(fname))
    if match and match.groups()[0].lower() in ('tzx', 'tap'):
        ext = match.groups()[0].lower()
        tfname = os.path.join(TEMP_DIR, getName(fname) + os.extsep + ext)
        options.extend(['--%s' % ext, fname, '-o', tfname] + prep)
    else:
        ext = 'asm'
        if not UPDATE:
            tfname = os.path.join(TEMP_DIR, 'test' + fname + os.extsep + ext)
        else:
            tfname = getName(fname) + os.extsep + ext
        options.extend(['--asm', fname, '-o', tfname] + prep)

    return options, tfname, ext


def testPREPRO(fname, pattern_=None):
    global UPDATE

    tfname = os.path.join(TEMP_DIR, 'test' + fname + os.extsep + 'out')
    prep = ' 2> /dev/null' if CLOSE_STDERR else ''
    okfile = getName(fname) + os.extsep + 'out'
    OPTIONS = ''
    match = reOPT.match(getName(fname))
    if match:
        OPTIONS = '-O' + match.groups()[0]

    if UPDATE:
        tfname = okfile

    syscmd = '{0} {1} {2} > {3}{4}'.format(ZXBPP, OPTIONS, fname, tfname, prep)
    result = None
    with TempTestFile(lambda: systemExec(syscmd), tfname, UPDATE) as err_lvl:
        if not UPDATE and not err_lvl:
            result = is_same_file(okfile, tfname, replace_regexp=pattern_,
                                  replace_what=ZXBASIC_ROOT, replace_with=_original_root)
    return result


def testASM(fname, inline=None):
    if inline is None:
        inline = INLINE

    tfname = os.path.join(TEMP_DIR, 'test' + fname + os.extsep + 'bin')
    prep = ['-e', '/dev/null'] if CLOSE_STDERR else ['-e', STDERR]
    okfile = getName(fname) + os.extsep + 'bin'

    if UPDATE:
        tfname = okfile

    options = [fname, '-o', tfname] + prep

    if inline:
        func = lambda: zxbasm.main(options)
    else:
        cmdline = '{0} {1}'.format(ZXBASM, ' '.join(options))
        func = lambda: systemExec(cmdline)

    result = None
    with TempTestFile(func, tfname, UPDATE):
        if not UPDATE:
            result = is_same_file(okfile, tfname, is_binary=True)

    return result


def testBAS(fname, filter_=None, inline=None):
    """ Test compiling a BASIC (.bas) file. Test is done by compiling the source code into asm and then
    comparing the output asm against an expected asm output. The output asm file can optionally be filtered
    using a filter_ regexp (see above).

    :param fname: Filename (.bas file) to test.
    :param filter_: regexp for filtering output before comparing. It will be ignored for binary (tzx, tap, etc) files
    :param inline: whether the test should be run inline or using the system shell
    :return: True on success false if not
    """
    if inline is None:
        inline = INLINE

    options, tfname, ext = _get_testbas_options(fname)
    okfile = getName(fname) + os.extsep + ext

    if inline:
        func = lambda: zxb.main(options + ['-I', ':'.join(os.path.join(ZXBASIC_ROOT, x)
                                                          for x in ('library', 'library-asm'))])
    else:
        syscmd = '{0} {1}'.format(ZXB, ' '.join(options))
        func = lambda: systemExec(syscmd)

    result = None
    with TempTestFile(func, tfname, UPDATE):
        if not UPDATE:
            result = is_same_file(okfile, tfname, filter_, is_binary=reBIN.match(fname) is not None)

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
            result = testASM(fname, inline=INLINE)
        elif ext == 'bas':
            result = testBAS(fname, filter_=FILTER, inline=INLINE)
        elif ext == 'bi':
            result = testPREPRO(fname, pattern_=FILTER)
        else:
            result = None

        COUNTER += 1
        _msg(("%4i " % COUNTER) + fname + ':')

        if result:
            _msg('ok        \r')
            FOUT.flush()
        elif result is None:
            _msg('?\r')
        else:
            FAILED += 1
            EXIT_CODE = 1
            _msg('FAIL\n')


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
        options, tfname, ext = _get_testbas_options(fname)
        if zxb.main(options):
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
                _msg('"%s"%s"%s"\n' % (x.strip(), c, y.strip()))
            os.unlink(tfname)
            continue  # Not the same diff

        os.unlink(fname1)
        os.rename(tfname, fname1)
        _msg("\rTest: %s (%s) updated\n" % (fname, fname1))


def set_temp_dir(tmp_dir=None):
    global TEMP_DIR
    temp_dir_created = True

    if tmp_dir is not None:
        TEMP_DIR = os.path.abspath(tmp_dir)
        if not os.path.isdir(TEMP_DIR):
            _error("Temporary directory '%s' does not exists" % TEMP_DIR, 1)
        temp_dir_created = False  # Already created externally
    else:
        TEMP_DIR = tempfile.mkdtemp(suffix='tmp', prefix='test_', dir=CURR_DIR)
    return temp_dir_created


def main(argv=None):
    """ Launches the testing using the arguments (argv) list passed.
    If argv is None, sys.argv[1:] will be used as default.
    E.g. to force update of test1.bas and test2.bas:
        main(['-U', 'test1.bas', 'test2.bas'])

    Does NOT accept file wildcard shell expansion ('*.bas').
    """
    global EXIT_CODE
    global PRINT_DIFF
    global VIM_DIFF
    global UPDATE
    global TEMP_DIR
    global QUIET
    global STDERR
    global INLINE

    parser = argparse.ArgumentParser(description='Test compiler output against source code samples')
    parser.add_argument('-d', '--show-diff', action='store_true', help='Shows output difference on failure')
    parser.add_argument('-v', '--show-visual-diff', action='store_true', help='Shows visual difference using vimdiff '
                                                                              'upon failure')
    parser.add_argument('-u', '--update', type=str, default=None, help='Updates all *.bas test if the UPDATE diff'
                                                                       ' matches')
    parser.add_argument('-U', '--force-update', action='store_true', help='Updates all failed test with the new output')
    parser.add_argument('--tmp-dir', type=str, default=TEMP_DIR, help='Temporary directory for tests generation')
    parser.add_argument('FILES', nargs='+', type=str, help='List of files to be processed')
    parser.add_argument('-q', '--quiet', action='store_true', help='Run quietly, suppressing normal output')
    parser.add_argument('-e', '--stderr', type=str, default=STDERR, help='File for stderr messages')
    parser.add_argument('-S', '--use-shell', action='store_true', help='Use system shell for test instead of inline')
    args = parser.parse_args(argv)

    STDERR = args.stderr
    INLINE = not args.use_shell

    temp_dir_created = False
    try:
        QUIET = args.quiet
        PRINT_DIFF = args.show_diff
        VIM_DIFF = args.show_visual_diff
        UPDATE = args.force_update

        temp_dir_created = set_temp_dir(args.tmp_dir)

        if args.update:
            upgradeTest(args.FILES, args.update)
        else:
            testFiles(args.FILES)

    finally:
        if temp_dir_created:
            os.rmdir(TEMP_DIR)
            TEMP_DIR = None

    return EXIT_CODE


if __name__ == '__main__':
    CLOSE_STDERR = True
    main()

    if COUNTER:
        _msg("Total: %i, Failed: %i (%3.2f%%)\n" % (COUNTER, FAILED, 100.0 * FAILED / float(COUNTER)))
    else:
        _msg("No tests found\n")
        EXIT_CODE = 1

    sys.exit(EXIT_CODE)
