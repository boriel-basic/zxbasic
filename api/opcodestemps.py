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
    """ Manages a table of Tn temporal values.
        This should be a SINGLETON container
    """
    def __init__(self):
        self.data = singleton

    def new_t(self):
        """ Returns a new t-value name
        """
        self.data.count += 1
        return 't%i' % (self.data.count - 1)
