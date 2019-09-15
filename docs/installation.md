#Installation

##Installation of ZX Basic SDK
ZX Basic SDK comes in two flavours:

* Multiplatform (Linux / Windows / Mac) python scripts. This is the main distribution and recommended for everyone.
* Windows .MSI Installer.

The latest is only for Windows users who are not able or very lazy to use python scripts directly. This .MSI distribution is not updated as often as the Multiplatform one, but has the advantage of not requiring to have the python interpreter previously installed.

###Prerequisites
For the _Multi-platform_ bundle, you will need the [python](http://www.python.org) interpreter **version 3.5** or
higher installed on your system (Linux and Mac OS X users will probably have it already installed since
it is very common on those operating systems).
For Windows users, there's also a python interpreter from [ActiveState](http://www.activestate.com),
the [ActivePython](http://www.activestate.com/store/download.aspx?prdGUID=b08b04e0-6872-4d9d-a722-7a0c2dea2758)
interpreter, 100% python compatible (Windows users who choose the .ZIP package distribution does not need to install
any python interpreter).

###Downloading
To get the latest version of the ZX BASIC SDK, go to the [Download Page](http://www.boriel.com/files/zxb/),
and get the `tar.gz` or `.ZIP` file you want. The .ZIP files are _Multiplatform_ (Linux / Windows / Mac), except those
with the `win32` suffix, which are for Windows only.

###Installing
Installing the .MSI distribution is pretty straightforward:
They **do not require any installation**. Just uncompress the SDK tree in a directory of your choice and make sure
that folder is included in your PATH environment variable.


##Testing your installation
For the .ZIP distribution, type **zxb.py** (in windows you can type **zxb**).
You should see something like:
```
 >zxb.py
 Usage: zxb.py <input file> [options]
 
 zxb.py: error: missing input file. (Try -h)
```
Ok, the compiler is working (or it seems so). Now you should proceed to the following section to learn about its usage.
