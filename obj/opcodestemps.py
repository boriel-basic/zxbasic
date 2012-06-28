#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

class __Singleton(object):
    pass


singleton = __Singleton()
singleton.table = {}
singleton.count = 0


class OpcodesTemps(object):
    ''' Manages a table of Tn temporal values.
        This should be a SINGLETON container
    '''

    def __init__(self):
        '''
        self.table = {}
        self.count = 0
        '''
        self.data = singleton

    '''
    @classmethod
    def __new__(clss, *args, **kwargs):
        global __singleton

        if __singleton is None:
            __singleton = object.__new__(clss)

        return clss._singleton
    '''


    def new_t(self):
        ''' Returns a new t-value name
        '''
        #self.count += 1
        self.data.count += 1

        #return 't%i' % (self.count - 1)
        return 't%i' % (self.data.count - 1)
        


