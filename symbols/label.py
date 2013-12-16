#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from api.constants import CLASS
from var import SymbolVAR


class SymbolLABEL(SymbolVAR):
    def __init__(self, name, lineno):
        SymbolVAR.__init__(self, name, lineno)
        self.class_ = CLASS.label
