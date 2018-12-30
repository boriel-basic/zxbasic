# -*- coding: utf-8 -*-

import unittest

from arch.zx48k.optimizer import memcell


class TestMemCell(unittest.TestCase):
    def test_or_a(self):
        """ ORing A with itself does not destroys A, only F. But requires A
        as input, since it's value is used to compute F
        """
        c = memcell.MemCell('or a', 1)
        self.assertSetEqual(c.requires, {'a'})
        self.assertSetEqual(c.destroys, {'f'})

    def test_or_b(self):
        """ Test ORing with an 8 bit register, other than A
        """
        c = memcell.MemCell('or b', 1)
        self.assertSetEqual(c.requires, {'a', 'b'})
        self.assertSetEqual(c.destroys, {'a', 'f'})

    def test_cp_a(self):
        """ Comparing A with itself does not destroys A, only F.
        Does not requires A as input, since it's value is always known
        A is unchanged, F will have Z = 0, C = 0.
        Other values P/V, S are unknown, but not used by the compiler.
        """
        c = memcell.MemCell('cp a', 1)
        self.assertSetEqual(c.requires, set())
        self.assertSetEqual(c.destroys, {'f'})

    def test_cp_b(self):
        """ Test CPing with an 8 bit register, other than A
        """
        c = memcell.MemCell('cp b', 1)
        self.assertSetEqual(c.requires, {'a', 'b'})
        self.assertSetEqual(c.destroys, {'f'})

    def test_sub_a(self):
        """ Subtracting A with itself does not destroys A, only F.
        Does not requires A as input, since it's value is always known:
        A = 0, F will have Z = 0, C = 0.
        Other values P/V, S are unknown, but not used by the compiler.
        """
        c = memcell.MemCell('sub a', 1)
        self.assertSetEqual(c.requires, set())
        self.assertSetEqual(c.destroys, {'a', 'f'})

    def test_sub_b(self):
        """ Test subtracting with an 8 bit register, other than A
        """
        c = memcell.MemCell('sub b', 1)
        self.assertSetEqual(c.requires, {'a', 'b'})
        self.assertSetEqual(c.destroys, {'a', 'f'})

    def test_requires_pragma(self):
        """ Test requires function with #pragma opt require
        """
        c = memcell.MemCell('#pragma opt require hl, de, bc', 1)
        self.assertSetEqual(c.requires, {'h', 'l', 'd', 'e', 'b', 'c'})

    def test_require_ldir(self):
        """ Test requires of ldir instruction
        """
        c = memcell.MemCell('ldir', 1)
        self.assertSetEqual(c.requires, {'h', 'l', 'd', 'e', 'b', 'c'})
        self.assertSetEqual(c.destroys, {'h', 'l', 'd', 'e', 'b', 'c', 'f'})
