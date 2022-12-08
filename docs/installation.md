# Installation

## Installation of ZX Basic SDK
ZX Basic SDK comes two several flavours:

* OS Specific binary package (the recommended way).<br />
  For Windows, Mac OS and Linux
* Multiplatform python scripts (will require Python 3.8+ to be installed in your system)

### Prerequisites
For the _Multi-platform_ bundle, you will need a [python](http://www.python.org) interpreter **version 3.8** or
higher installed in your system (Linux and Mac OS X users will probably have it already).

### Downloading
To get the latest version of the ZX BASIC SDK, head to [Download Page](https://zxbasic.readthedocs.io/en/docs/archive/),
and get the file you want.

### Installation
Installation is pretty straightforward: Just uncompress the SDK tree in a directory of your choice and make sure
the folder is included in your PATH environment variable.

## Testing your installation
For the binary distribution type **zxbc** (ensure this file is in your PATH).
You should see something like:
```
 >zxbc
 Usage: zxbc <input file> [options]
 
 zxbc: error: missing input file. (Try -h)
```

For the python distribution type **zxbc.py** (in windows you can type **zxbc**).
You should see something like:
```
 >zxbc.py
 Usage: zxbc.py <input file> [options]
 
 zxbc.py: error: missing input file. (Try -h)
```

Ok, the compiler is working (or it seems so). Now you should proceed to the following section to learn about its usage.

