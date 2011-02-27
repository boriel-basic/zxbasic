#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------


class OpcodesTemps(object):
    ''' Manages a table of Tn temporal values.
        This should be a SINGLETON container
    '''
    _singleton = None

    def __init__(self):
        self.table = {}
        self.count = 0

    @classmethod
    def __new__(clss, *args, **kwargs):
        if clss._singleton is None:
            clss._singleton = object.__new__(clss)

        return clss._singleton


    def new_t(self):
        ''' Returns a new t-value name
        '''
        self.count += 1

        return 't%i' % (self.count - 1)


