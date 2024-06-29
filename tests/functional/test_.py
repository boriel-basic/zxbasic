#!/usr/bin/env python3
# vim:ts=4:et:ai

import doctest
import os
import sys
from io import StringIO

import test


class OutputProxy(StringIO):
    """A simple interface to replace sys.stdout so
    doctest can capture it.
    """

    def write(self, str_):
        sys.stdout.write(str_)

    def flush(self):
        sys.stdout.flush()


def process_file(fname: str, params=None):
    if params is None:
        params = ["-S", "-q"]
        if fname.lower().endswith(".bas"):
            params.append("-O --hide-warning-codes")

    try:
        current_path = os.path.abspath(os.getcwd())
        test.set_temp_dir()
        test.FOUT = OutputProxy()
        if os.path.dirname(fname).startswith("/"):
            os.chdir(os.path.abspath(os.path.dirname(fname)))
            fname = os.path.basename(fname)
        else:
            os.chdir(os.path.realpath(os.path.join(os.path.dirname(__file__), os.path.dirname(fname))))
        test.main(params + [os.path.basename(fname)])
        os.chdir(current_path)
    finally:
        os.rmdir(test.TEMP_DIR)
        test.TEMP_DIR = None


def main():
    current_path = os.path.abspath(os.getcwd())
    os.chdir(os.path.realpath(os.path.dirname(__file__) or os.curdir))
    result = doctest.testfile("test_errmsg.txt")  # evaluates to True on failure
    if not result.failed:
        result = doctest.testfile("test_cmdline.txt")  # Evaluates to True on failure
    os.chdir(current_path)
    return int(result.failed)


if __name__ == "__main__":
    sys.exit(main())
