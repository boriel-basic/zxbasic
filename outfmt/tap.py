#!/usr/bin/python
# -*- coding: utf-8 -*-

# --------------------------------------------
# KopyLeft (K) 2008
# by Jose M. Rodriguez de la Rosa
#
# This program is licensed under the 
# GNU Public License v.3.0
#
# Simple .tap file library
# Only supports standard headers by now.
# --------------------------------------------

from tzx import TZX

class TAP(TZX):
    ''' Derived from TZX
    '''
    def __init__(self):
        ''' Initializes the object with standard header
        '''
        TZX.__init__(self)
        self.output = '' # Restarts the output


    def standard_block(self, bytes):
        ''' Adds a standard block of bytes. For TAP files, it's just the
        Low + Hi byte plus the content (here, the bytes plus the checksum)
        '''
        self.out(self.LH(len(bytes) + 1)) # + 1 for CHECKSUM byte

        checksum = 0
        for i in bytes:
            checksum ^= (int(i) & 0xFF)
            self.out(i)

        self.out(checksum)



if __name__ == '__main__':
    ''' Sample test if invoked from command line
    '''
    t = TAP()
    t.save_code('taptest', 16384, range(255))
    t.dump('tzxtest.tap')

