import sys

PYTHON_VERSION = 3, 10  # Minimum python version required

if tuple(sys.version_info) < PYTHON_VERSION:
    sys.stderr.write(
        "%s Error: Python version %s or higher is required\n"
        % (sys.argv[0], (".".join(str(x) for x in PYTHON_VERSION)))
    )
    sys.exit(1)
