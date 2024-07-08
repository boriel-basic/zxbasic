#!/usr/bin/env python3
# vim: ts=4:sw=4:et:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
#
# This is the Parser for the ZXBpp (ZXBasic Preprocessor)
# ----------------------------------------------------------------------

import os
import sys

sys.path.append(os.path.dirname(__file__))

from src import zxbpp  # noqa: E402

if __name__ == "__main__":
    sys.exit(zxbpp.entry_point())
