#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:ts=4:et:ai:

import argparse
import difflib
import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile
from typing import Callable, Iterable

reOPT = re.compile(r"^opt([0-9]+)_")  # To detect -On tests
reBIN = re.compile(r"^(?:.*/)?(tzx|tap)_.*")  # To detect tzx / tap test

EXIT_CODE = 0
FILTER = r"^(([ \t]*;)|(#[ \t]*line))"
DEFAULT_ARCH = "zx48k"  # Default testing architecture

# Global tests and failed counters
COUNTER = 0
FAILED = 0
CURR_DIR = os.path.dirname(os.path.realpath(__file__))
ZXBASIC_ROOT = os.path.abspath(os.path.join(CURR_DIR, os.path.pardir, os.path.pardir))
ZXB = os.path.join(ZXBASIC_ROOT, "zxbc.py")
ZXBASM = os.path.join(ZXBASIC_ROOT, "zxbasm.py")
ZXBPP = os.path.join(ZXBASIC_ROOT, "zxbpp.py")

# Fake root of preprocessed files to standardize output
_original_root = "/zxbasic"

sys.path.append(ZXBASIC_ROOT)  # TODO: consider moving test.py to another place to avoid this

# Now we can import the modules from the root
import src.api.utils  # noqa
from src import zxbasm, zxbc, zxbpp  # noqa

# global FLAGS
CLOSE_STDERR = False  # Whether to show compiler error or not (usually not when doing tests)
PRINT_DIFF = False  # Will show diff on test failure
VIM_DIFF = False  # Will show visual diff using (g?)vimdiff on test failure
UPDATE: bool = False  # True and test will be updated on failure
FOUT = sys.stdout  # Output file. By default stdout but can be captured changing this
TEMP_DIR: str = ""
QUIET = False  # True so suppress output (useful for testing)
DEFAULT_STDERR = "/dev/stderr"
STDERR: str = ""
INLINE = True  # Set to false to use system Shell
RAISE_EXCEPTIONS = False  # True if we want the testing to abort on compiler crashes
TIMEOUT = 3  # Max number of seconds a test should last

_timeout = lambda: TIMEOUT


class TempTestFile(object):
    """Uses a python guard context to ensure file deletion.
    Executes a system command which creates a temporary file and
    ensures file deletion upon return.
    """

    def __init__(self, func: Callable[[], int], fname: str, *, keep_file: bool = False):
        """Initializes the context. The flag keep_file will be taken into account
        only if the System command execution was successful (returns 0)
        :param func: Function to execute
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
            except (OSError, FileNotFoundError):
                pass  # Ok. It might be that it wasn't created


def _error(msg: str, exit_code: int | None = None) -> None:
    """Shows an error msg to sys.stderr and optionally
    exits if exit code is not None
    """
    sys.stderr.write("%s\n" % msg)
    if exit_code is not None:
        exit(exit_code)


def _msg(msg: str, *, force: bool = False) -> None:
    """Shows a msg to the FOUT output if not in QUIET mode or force == True"""
    if not QUIET or force:
        FOUT.write(msg)


def get_file_lines(
    filename: str,
    ignore_regexp: str | None = None,
    replace_regexp: str | None = None,
    replace_what: str = ".",
    replace_with: str = ".",
    strip_blanks: bool = True,
) -> list[str]:
    """Opens source file <filename> and load its lines,
    discarding those not important for comparison.
    """
    from src.api.utils import open_file

    with open_file(filename, "rt", "utf-8") as f:
        lines = [x.rstrip("\r\n") for x in f]

    if ignore_regexp is not None:
        r = re.compile(ignore_regexp)
        lines = [x for x in lines if not r.search(x)]

    if replace_regexp is not None and replace_what and replace_with is not None:
        r = re.compile(replace_regexp)
        lines = [x.replace(replace_what, replace_with, 1) if r.search(x) else x for x in lines]

    if strip_blanks:
        lines = [x.rstrip(" \t") for x in lines if x.rstrip(" \t")]

    return lines


def is_same_file(
    fname1: str,
    fname2: str,
    ignore_regexp: str | None = None,
    replace_regexp: str | None = None,
    replace_what: str = ".",
    replace_with: str = ".",
    diff: list[str] | None = None,
    *,
    is_binary: bool = False,
    strip_blanks: bool = True,
) -> bool:
    """Test if two files are the same.

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
        return open(fname1, "rb").read() == open(fname2, "rb").read()

    r1 = get_file_lines(fname1, ignore_regexp, replace_regexp, replace_what, replace_with, strip_blanks)
    r2 = get_file_lines(fname2, ignore_regexp, replace_regexp, replace_what, replace_with, strip_blanks)
    result = r1 == r2

    if not result:
        if diff is None:
            diff = []
        diff.extend(difflib.unified_diff(r1, r2, fname1, fname2, lineterm=""))

    if PRINT_DIFF and not result:
        if VIM_DIFF:
            systemExec("gvimdiff %s %s" % (fname1, fname2))
        else:
            sys.stdout.write("\n".join(diff or []) + "\n")

    return result


def systemExec(command: str, stdout: int = subprocess.PIPE, stderr: int = subprocess.STDOUT) -> int:
    result = subprocess.Popen(command, bufsize=-1, shell=True, stdout=stdout, stderr=stderr)
    exit_code = result.wait()
    assert result.stdout is not None
    FOUT.write(result.stdout.read().decode("utf-8"))
    return exit_code


def getExtension(fname: str) -> str | None:
    """Returns filename extension.
    Returns None if no extension.
    """
    split = os.path.basename(fname).split(os.extsep)
    return split[-1] if len(split) > 1 else None


def getName(fname: str) -> str:
    """Returns filename (without extension)"""
    basename = os.path.basename(fname)
    if getExtension(basename) is None:
        return basename

    return basename.split(os.extsep)[0]


def _get_testbas_options(fname: str) -> tuple[list[str], str, str]:
    """Generates a command line string to be executed to
    get the .asm test file from a .bas one.
    :param str fname: .bas filename source file
    :rtype: tuple
    :return: a tuple containing (in this order),
            - the command line to be used
            - the test .asm file that will be generated
            - the extension of the file (normally .asm)
    """
    prep = ["-e", "/dev/null"] if CLOSE_STDERR else ["-e", STDERR]
    options = ["-O1"]

    arch = os.path.dirname(fname).split(os.path.sep)[-1] or DEFAULT_ARCH
    options.extend(["--arch", arch])

    match = reOPT.match(getName(fname))
    if match:
        options.append("-O" + match.groups()[0])

    match = reBIN.match(getName(fname))
    if match and match.groups()[0].lower() in ("tzx", "tap"):
        ext = match.groups()[0].lower()
        tfname = os.path.join(TEMP_DIR, getName(fname) + os.extsep + ext)
        options.extend(["--%s" % ext, fname, "-o", tfname, "-a", "-B"] + prep)
    else:
        ext = "asm"
        tfname = os.path.join(TEMP_DIR, "test" + getName(fname) + os.extsep + ext)
        options.extend(["--asm", fname, "-o", tfname] + prep)
    return options, tfname, ext


def updateTest(tfname: str, pattern_: str | None, strip_blanks: bool = True) -> None:
    if not os.path.exists(tfname):
        return  # was deleted -> The test is an error test and no compile file should exist

    if reBIN.match(tfname):  # Binary files do not need updating
        return

    lines = get_file_lines(
        tfname,
        replace_regexp=pattern_,
        replace_what=ZXBASIC_ROOT,
        replace_with=_original_root,
        strip_blanks=strip_blanks,
    )
    with src.api.utils.open_file(tfname, "wt", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


@src.api.utils.timeout(_timeout)
def testPREPRO(
    fname: str, pattern_: str | None = None, inline: bool | None = None, cmdline_args: list[str] | None = None
) -> bool | None:
    """Test preprocessing file. Test is done by preprocessing the file and then
    comparing the output against an expected one. The output file can optionally be filtered
    using a filter_ regexp (see above).

    :param fname: Filename (usually a .bi file) to test.
    :param pattern_: regexp for filtering output before comparing. It will be ignored for binary (tzx, tap, etc) files
    :param inline: whether the test should be run inline or using the system shell
    :return: True on success false if not
    """
    global UPDATE

    if inline is None:
        inline = INLINE

    if cmdline_args is None:
        cmdline_args = []

    tfname = os.path.join(TEMP_DIR, "test" + getName(fname) + os.extsep + "out")
    okfile = os.path.join(os.path.dirname(fname), getName(fname) + os.extsep + "out")

    if UPDATE:
        tfname = okfile
        if os.path.exists(okfile):
            os.unlink(okfile)

    prep = ["-e", "/dev/null"] if CLOSE_STDERR else ["-e", STDERR]
    if UPDATE:
        tfname = okfile
        if os.path.exists(okfile):
            os.unlink(okfile)

    options = [os.path.basename(fname), "-o", tfname] + prep
    options.extend(cmdline_args)

    if inline:
        func = lambda: zxbpp.entry_point(options)
    else:
        cmdline = "{0} {1}".format(ZXBPP, " ".join(options))
        func = lambda: systemExec(cmdline)

    result = None
    current_path: str = os.getcwd()

    try:
        os.chdir(os.path.dirname(fname) or os.curdir)

        with TempTestFile(func, tfname, keep_file=UPDATE):
            if not UPDATE:
                result = is_same_file(
                    okfile,
                    tfname,
                    replace_regexp=pattern_,
                    replace_what=ZXBASIC_ROOT,
                    replace_with=_original_root,
                    strip_blanks=False,
                )
            else:
                updateTest(tfname, pattern_, strip_blanks=False)
    finally:
        os.chdir(current_path)

    return result


@src.api.utils.timeout(_timeout)
def testASM(fname, inline=None, cmdline_args=None):
    """Test assembling an ASM (.asm) file. Test is done by assembling the source code into a binary and then
    comparing the output file against an expected binary output.

    :param fname: Filename (.asm file) to test.
    :param inline: whether the test should be run inline or using the system shell
    :return: True on success false if not
    """
    if inline is None:
        inline = INLINE

    if cmdline_args is None:
        cmdline_args = []

    tfname = os.path.join(TEMP_DIR, "test" + getName(fname) + os.extsep + "bin")
    prep = ["-e", "/dev/null"] if CLOSE_STDERR else ["-e", STDERR]
    okfile = os.path.join(os.path.dirname(fname), getName(fname) + os.extsep + "bin")

    if UPDATE:
        tfname = okfile
        if os.path.exists(okfile):
            os.unlink(okfile)

    options = [fname, "-o", tfname] + prep
    if fname.startswith("zxnext_"):
        options.append("--zxnext")
    options.extend(cmdline_args)

    if inline:
        func = lambda: zxbasm.main(options)
    else:
        cmdline = "{0} {1}".format(ZXBASM, " ".join(options))
        func = lambda: systemExec(cmdline)

    result = None
    with TempTestFile(func, tfname, keep_file=UPDATE):
        if not UPDATE:
            result = is_same_file(okfile, tfname, is_binary=True)

    return result


@src.api.utils.timeout(_timeout)
def testBAS(
    fname: str, filter_=None, inline: bool | None = None, cmdline_args: Iterable[str] | None = None
) -> bool | None:
    """Test compiling a BASIC (.bas) file. Test is done by compiling the source code into asm and then
    comparing the output asm against an expected asm output. The output asm file can optionally be filtered
    using a filter_ regexp (see above).

    :param fname: Filename (.bas file) to test.
    :param filter_: regexp for filtering output before comparing. It will be ignored for binary (tzx, tap, etc) files
    :param inline: whether the test should be run inline or using the system shell
    :return: True on success false if not
    """
    if inline is None:
        inline = INLINE

    if cmdline_args is None:
        cmdline_args = []

    options, tfname, ext = _get_testbas_options(fname)
    options.extend(cmdline_args)
    okfile = os.path.join(os.path.dirname(fname), getName(fname) + os.extsep + ext)

    if inline:
        func = lambda: zxbc.main(
            options + ["-I", ":".join(os.path.join(ZXBASIC_ROOT, x) for x in ("library", "library-asm"))]
        )
    else:
        syscmd = "{0} {1}".format(ZXB, " ".join(options))
        func = lambda: systemExec(syscmd)

    with TempTestFile(func, tfname, keep_file=UPDATE):
        result: bool | None = is_same_file(okfile, tfname, filter_, is_binary=reBIN.match(fname) is not None)
        if UPDATE:
            if not result:  # File changed
                if os.path.exists(okfile):
                    os.unlink(okfile)
                if os.path.exists(tfname):
                    updateTest(tfname, FILTER)
                    shutil.move(tfname, okfile)
                    result = None
            else:  # The file has not changed. Delete it
                if os.path.exists(tfname):
                    os.unlink(tfname)

    return result


def testFiles(file_list: Iterable[str], cmdline_args=None) -> None:
    """Run tests for the given file extension"""
    global EXIT_CODE, COUNTER, FAILED, RAISE_EXCEPTIONS

    COUNTER = 0
    if cmdline_args is None:
        cmdline_args = []

    for fname in file_list:
        fname = fname
        ext = getExtension(fname)
        try:
            if ext == "asm":
                if os.path.exists(os.path.join(os.path.dirname(fname), getName(fname) + os.extsep + "bas")):
                    continue  # Ignore asm files which have a .bas since they're test results
                result = testASM(fname, inline=INLINE, cmdline_args=cmdline_args)
            elif ext == "bas":
                result = testBAS(fname, filter_=FILTER, inline=INLINE, cmdline_args=cmdline_args)
            elif ext == "bi":
                result = testPREPRO(fname, pattern_=FILTER, inline=INLINE, cmdline_args=cmdline_args)
            else:
                result = None
        except Exception as e:  # noqa
            result = False
            _msg("{}: *CRASH* {} exception\n".format(fname, type(e).__name__))
            if RAISE_EXCEPTIONS:
                raise

        COUNTER += 1
        _msg(("%4i " % COUNTER) + getName(fname) + ":")

        if result:
            _msg("ok        \r")
            FOUT.flush()
        elif result is None:
            _msg("?\r")
        else:
            FAILED += 1
            EXIT_CODE = 1
            _msg("FAIL\n")


def upgradeTest(filelist: Iterable[str], f3diff: str) -> None:
    """Run against the list of files, and a 3rd file containing the diff.
    If the diff between file1 and file2 are the same as file3, then the
    .asm file is patched.
    """
    global COUNTER

    def normalizeDiff(diff: list[str]) -> list[str]:
        diff = [x.strip(" \t") for x in diff]

        reHEADER = re.compile(r"[-+]{3}")
        while diff and reHEADER.match(diff[0]):
            diff = diff[1:]

        O1 = O2 = 0
        first = True
        reHUNK = re.compile(r"@@ [-+](\d+)(,\d+)? [-+](\d+)(,\d+)? @@")

        for i in range(len(diff)):
            line = diff[i]
            if line[:7] in ("-#line ", "+#line "):
                diff[i] = ""
                continue

            match = reHUNK.match(line)
            if match:
                g = match.groups()
                g = tuple(x if x is not None else "" for x in g)
                if first:
                    first = False
                    O1 = int(g[0])
                    O2 = int(g[2])

                diff[i] = "@@ -%(a)s%(b)s +%(c)s%(d)s\n" % {
                    "a": int(g[0]) - O1,
                    "b": g[1],
                    "c": int(g[2]) - O2,
                    "d": g[3],
                }

        return diff

    with open(f3diff, "rt", encoding="utf-8") as patch_file:
        fdiff = [line.rstrip("\n") for line in patch_file]

    fdiff = normalizeDiff(fdiff)

    for fname in filelist:
        ext = getExtension(fname)
        if ext != "bas":
            continue

        if testBAS(fname):
            continue

        fname0 = getName(fname)
        fname1 = fname0 + os.extsep + "asm"
        options, tfname, ext = _get_testbas_options(fname)
        if zxbc.main(options):
            try:
                os.unlink(tfname)
            except OSError:
                pass
            continue

        lines: list[str] = []
        is_same_file(fname1, tfname, ignore_regexp=FILTER, diff=lines)
        lines = normalizeDiff(lines)

        if lines[: len(fdiff)] != fdiff:
            for x, y in zip(lines, fdiff):
                x = x.strip()
                y = y.strip()
                c = "=" if x == y else "!"
                _msg('"%s" %s "%s"\n' % (x.strip(), c, y.strip()))
            os.unlink(tfname)
            continue  # Not the same diff

        lines = get_file_lines(tfname, replace_regexp=FILTER, replace_what=ZXBASIC_ROOT, replace_with=_original_root)
        with src.api.utils.open_file(fname1, "wt", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")

        os.unlink(tfname)
        _msg("\rTest: %s (%s) updated\n" % (fname, fname1))
        COUNTER += 1


def set_temp_dir(tmp_dir=None):
    global TEMP_DIR
    temp_dir_created = True

    if tmp_dir is not None:
        TEMP_DIR = os.path.abspath(tmp_dir)
        if not os.path.isdir(TEMP_DIR):
            _error("Temporary directory '%s' does not exists" % TEMP_DIR, 1)
        temp_dir_created = False  # Already created externally
    else:
        TEMP_DIR = tempfile.mkdtemp(suffix="tmp", prefix="test_", dir=CURR_DIR)
    return temp_dir_created


def main(argv=None):
    """Launches the testing using the arguments (argv) list passed.
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
    global CLOSE_STDERR
    global COUNTER
    global FAILED
    global EXIT_CODE
    global RAISE_EXCEPTIONS
    global TIMEOUT

    COUNTER = FAILED = EXIT_CODE = 0

    parser = argparse.ArgumentParser(description="Test compiler output against source code samples")
    parser.add_argument("-d", "--show-diff", action="store_true", help="Shows output difference on failure")
    parser.add_argument(
        "-v", "--show-visual-diff", action="store_true", help="Shows visual difference using vimdiff " "upon failure"
    )
    parser.add_argument("-u", "--update", type=str, default=None, help="Updates a test if the UPDATE diff matches")
    parser.add_argument("-U", "--force-update", action="store_true", help="Updates all failed test with the new output")
    parser.add_argument("--tmp-dir", type=str, default=TEMP_DIR, help="Temporary directory for tests generation")
    parser.add_argument("FILES", nargs="+", type=str, help="list of files to be processed")
    parser.add_argument("-q", "--quiet", action="store_true", help="Run quietly, suppressing normal output")
    parser.add_argument("-e", "--stderr", type=str, default=None, help="File for stderr messages")
    parser.add_argument("-S", "--use-shell", action="store_true", help="Use system shell for test instead of inline")
    parser.add_argument(
        "-O", "--option", action="append", help="Option to pass to compiler in a test (can be used many times)"
    )
    parser.add_argument(
        "-E",
        "--raise-exceptions",
        action="store_true",
        help="If an exception is raised (i.e." "the compiler crashes) the testing will " "stop with such exception",
    )
    args = parser.parse_args(argv)

    STDERR = args.stderr
    if STDERR:
        CLOSE_STDERR = False
    else:
        STDERR = DEFAULT_STDERR

    INLINE = not args.use_shell
    RAISE_EXCEPTIONS = args.raise_exceptions

    temp_dir_created = False
    try:
        QUIET = args.quiet
        PRINT_DIFF = args.show_diff
        VIM_DIFF = args.show_visual_diff
        UPDATE = args.force_update

        if VIM_DIFF:
            TIMEOUT = 0  # disable timeout for Vim-dif

        temp_dir_created = set_temp_dir(args.tmp_dir)
        files = sorted({fname for pattern in args.FILES for fname in glob.glob(pattern, recursive=True)})

        if args.update:
            upgradeTest(files, args.update)
        else:
            testFiles(files, args.option)

    finally:
        if temp_dir_created:
            os.rmdir(TEMP_DIR)
            TEMP_DIR = ""

    return EXIT_CODE


if __name__ == "__main__":
    CLOSE_STDERR = True
    main()

    if COUNTER:
        _msg("Total: %i, Failed: %i (%3.2f%%)\n" % (COUNTER, FAILED, 100.0 * FAILED / float(COUNTER)))
    else:
        _msg("No tests found\n")
        EXIT_CODE = 1

    sys.exit(EXIT_CODE)
