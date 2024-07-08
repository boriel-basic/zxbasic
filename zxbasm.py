#!/usr/bin/env python3
# vim: ts=4:et:sw=4

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
#
# This is the Parser for the ZXBASM (ZXBasic Assembler)
# ----------------------------------------------------------------------

import os
import sys

sys.path.append(os.path.dirname(__file__))

from src import zxbasm  # noqa: E402

if __name__ == "__main__":
    sys.exit(zxbasm.main())
