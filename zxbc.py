#!/usr/bin/env python3
# vim: ts=4:sw=4:et:

import os
import sys

sys.path.append(os.path.dirname(__file__))

from src import zxbc  # noqa: E402

if __name__ == "__main__":
    sys.exit(zxbc.main())  # Exit
