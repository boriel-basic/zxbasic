#!/usr/bin/env python
# -*- coding: utf-8 -*-

# --------------------------------------------
# KopyLeft (K) 2008
# by Jose M. Rodriguez de la Rosa
#
# This program is licensed under the 
# GNU Public License v.3.0
#
# Simple .tzx file library
# Only supports standard headers by now.
# --------------------------------------------


class TZX(object):
    """ Class to represent tzx data
    """
    VERSION_MAJOR = 1
    VERSION_MINOR = 21

    # Some interesting constants

    # TZX BLOCK TYPES
    BLOCK_STANDARD = 0x10

    # ZX Spectrum BLOCK Types
    BLOCK_TYPE_HEADER = 0
    BLOCK_TYPE_DATA = 0xFF

    # ZX Spectrum BASIC / ARRAY / CODE types
    HEADER_TYPE_BASIC = 0
    HEADER_TYPE_NUMBER_ARRAY = 1
    HEADER_TYPE_CHAR_ARRAY = 2
    HEADER_TYPE_CODE = 3

    def __init__(self):
        """ Initializes the object with standard header
        """
        self.output = bytearray(b'ZXTape!')
        self.out(0x1A)
        self.out([self.VERSION_MAJOR, self.VERSION_MINOR])

    def LH(self, value):
        """ Return a 16 bytes value as a list of 2 bytes [Low, High]
        """
        valueL = value & 0x00FF  # Low byte
        valueH = (value & 0xFF00) >> 8  # High byte

        return [valueL, valueH]

    def out(self, l):
        """ Adds a list of bytes to the output string
        """
        if not isinstance(l, list):
            l = [l]

        self.output.extend([int(i) & 0xFF for i in l])

    def standard_block(self, _bytes):
        """ Adds a standard block of bytes
        """
        self.out(self.BLOCK_STANDARD)  # Standard block ID
        self.out(self.LH(1000))  # 1000 ms standard pause
        self.out(self.LH(len(_bytes) + 1))  # + 1 for CHECKSUM byte

        checksum = 0
        for i in _bytes:
            checksum ^= (int(i) & 0xFF)
            self.out(i)

        self.out(checksum)

    def dump(self, fname):
        """ Saves TZX file to fname
        """
        open(fname, 'wb').write(self.output)

    def save_header(self, _type, title, length, param1, param2):
        """ Saves a generic standard header:
                type:   00 -- Program
                        01 -- Number Array
                        02 -- Char Array
                        03 -- Code

                title:  Name title.
                        Will be truncated to 10 chars and padded
                        with spaces if necessary.

                length: Data length (in bytes) of the next block.

                param1: For CODE -> Start address.
                        For PROGRAM -> Autostart line (>=32768 for no autostart)
                        For DATA (02 & 03) high byte of param1 have the variable name.

                param2: For CODE -> 32768
                        For PROGRAM -> Start of the Variable area relative to program Start (Length of basic in bytes)
                        For DATA (02 & 03) NOT USED

        Info taken from: http://www.worldofspectrum.org/faq/reference/48kreference.htm#TapeDataStructure
        """
        title = (title + 10 * ' ')[:10]  # Padd it with spaces
        title_bytes = [ord(i) for i in title]  # Convert it to bytes

        _bytes = [self.BLOCK_TYPE_HEADER, _type] + title_bytes + self.LH(length) + self.LH(param1) + self.LH(param2)
        self.standard_block(_bytes)

    def standard_bytes_header(self, title, addr, length):
        """ Generates a standard header block of CODE type
        """
        self.save_header(self.HEADER_TYPE_CODE, title, length, param1=addr, param2=32768)

    def standard_program_header(self, title, length, line=32768):
        """ Generates a standard header block of PROGRAM type
        """
        self.save_header(self.HEADER_TYPE_BASIC, title, length, param1=line, param2=length)

    def save_code(self, title, addr, _bytes):
        """ Saves the given bytes as code. If bytes are strings,
        its chars will be converted to bytes
        """
        self.standard_bytes_header(title, addr, len(_bytes))
        _bytes = [self.BLOCK_TYPE_DATA] + [(int(x) & 0xFF) for x in _bytes]  # & 0xFF truncates to bytes
        self.standard_block(_bytes)

    def save_program(self, title, bytes, line=32768):
        """ Saves the given bytes as a BASIC program.
        """
        self.standard_program_header(title, len(bytes), line)
        bytes = [self.BLOCK_TYPE_DATA] + [(int(x) & 0xFF) for x in bytes]  # & 0xFF truncates to bytes
        self.standard_block(bytes)


if __name__ == '__main__':
    """ Sample test if invoked from command line
    """
    t = TZX()
    t.save_code('tzxtest', 16384, range(255))
    t.dump('tzxtest.tzx')
