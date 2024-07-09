#!/usr/bin/env python3
# vim:ts=4:et:ai

import os
import sys
import tempfile
from io import StringIO
from typing import Final

import test

from src.api.utils import chdir

FILE_PATH: Final[str] = os.path.realpath(os.path.dirname(__file__) or os.curdir)


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

    params.extend(["--timeout", "60", "-E"])

    try:
        with tempfile.TemporaryDirectory() as tmp_dirname:
            if os.path.dirname(fname).startswith("/"):
                new_dir = os.path.abspath(os.path.dirname(fname))
                fname = os.path.basename(fname)
            else:
                new_dir = os.path.realpath(os.path.join(os.path.dirname(__file__), os.path.dirname(fname)))

            with chdir(new_dir):
                test.set_temp_dir(tmp_dirname)
                test.FOUT = OutputProxy()
                test.main(params + [os.path.basename(fname)])

    finally:
        test.TEMP_DIR = None
