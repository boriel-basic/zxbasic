#!/usr/bin/env python3

import sys

PYTHON_VERSION = 3, 10  # Minimum python version required

if tuple(sys.version_info) < PYTHON_VERSION:
    print(
        f"{sys.argv[0]} Error: minimum Python Version required is {'.'.join(str(x) for x in PYTHON_VERSION)}",
        file=sys.stderr,
    )
    sys.exit(1)
