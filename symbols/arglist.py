#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from .symbol_ import Symbol
from .argument import SymbolARGUMENT


class SymbolARGLIST(Symbol):
    """ Defines a list of arguments in a function call or array access
    """

    def __init__(self, *args):
        super(SymbolARGLIST, self).__init__(*args)

    @property
    def args(self):
        return self.children

    @args.setter
    def args(self, value):
        for i in value:
            assert isinstance(value, SymbolARGUMENT)
            self.appendChild(i)

    def __getitem__(self, range_):
        return self.args[range_]

    def __setitem__(self, range_, value):
        assert isinstance(value, SymbolARGUMENT)
        self.children[range_] = value

    def __str__(self):
        return '(%s)' % (', '.join(str(x) for x in self.args))

    def __repr__(self):
        return str(self)

    def __len__(self):
        return len(self.args)

    @classmethod
    def make_node(cls, node, *args):
        """ This will return a node with an argument_list.
        """
        if node is None:
            node = cls()

        assert isinstance(node, SymbolARGUMENT) or isinstance(node, cls)

        if not isinstance(node, cls):
            return cls.make_node(None, node, *args)

        for arg in args:
            assert isinstance(arg, SymbolARGUMENT)
            node.appendChild(arg)

        return node
