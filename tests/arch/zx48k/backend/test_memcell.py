# -*- coding: utf-8 -*-

import unittest

import src.arch
from src.arch.zx48k.optimizer import memcell


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

    def test_require_ex_de_hl(self):
        """ Test requires of ex de, hl instruction
        """
        c = memcell.MemCell('ex de, hl', 1)
        self.assertSetEqual(c.requires, {'h', 'l', 'd', 'e'})
        self.assertSetEqual(c.destroys, {'h', 'l', 'd', 'e'})

    def test_require_add_hl(self):
        """ Test requires of add hl, NN instruction
        """
        c = memcell.MemCell('add hl, de', 1)
        self.assertSetEqual(c.requires, {'h', 'l', 'd', 'e'})
        self.assertSetEqual(c.destroys, {'h', 'l', 'f'})
        c = memcell.MemCell('add hl, bc', 1)
        self.assertSetEqual(c.requires, {'h', 'l', 'b', 'c'})
        self.assertSetEqual(c.destroys, {'h', 'l', 'f'})

    def test_require_sbc_hl(self):
        """ Test requires of add hl, NN instruction
        """
        c = memcell.MemCell('sbc hl, de', 1)
        self.assertSetEqual(c.requires, {'h', 'l', 'd', 'e', 'f'})
        self.assertSetEqual(c.destroys, {'h', 'l', 'f'})
        c = memcell.MemCell('sbc hl, bc', 1)
        self.assertSetEqual(c.requires, {'h', 'l', 'b', 'c', 'f'})
        self.assertSetEqual(c.destroys, {'h', 'l', 'f'})

    def test_require_sbc_a_a(self):
        """ Test requires of sbc a, a instruction
        """
        c = memcell.MemCell('sbc a, a', 1)
        self.assertSetEqual(c.requires, {'f'})
        self.assertSetEqual(c.destroys, {'a', 'f'})

    def test_require_sub_1(self):
        """ Test requires of sub 1 instruction
        """
        c = memcell.MemCell('sub 1', 1)
        self.assertSetEqual(c.requires, {'a'})
        self.assertSetEqual(c.destroys, {'a', 'f'})

    def test_require_destroys_asm(self):
        """ For a user memory block, returns the list of required (ALL)
        and destroyed (ALL) registers
        """
        src.arch.zx48k.backend.ASMS['##ASM0'] = ['nop']
        c = memcell.MemCell('##ASM0', 1)
        self.assertEqual(c.destroys, {'a', 'b', 'c', 'd', 'e', 'f', 'h', 'l', 'ixh', 'ixl', 'iyh', 'iyl',
                                      'r', 'i', 'sp'})
        self.assertEqual(c.requires, {'a', 'b', 'c', 'd', 'e', 'f', 'h', 'l', 'ixh', 'ixl', 'iyh', 'iyl',
                                      'r', 'i', 'sp'})

        del src.arch.zx48k.backend.ASMS['##ASM0']

    def test_requires_xor_a(self):
        """ Test requires for xor a instruction
        """
        c = memcell.MemCell('xor a', 1)
        self.assertSetEqual(c.requires, set())
        self.assertSetEqual(c.destroys, {'a', 'f'})

    def test_require_out(self):
        """ Test requires for out(c), a instruction
        """
        c = memcell.MemCell('out (c), a', 1)
        self.assertSetEqual(c.requires, {'a', 'b', 'c'})
        self.assertSetEqual(c.destroys, set())

        c = memcell.MemCell('out (c), d', 1)
        self.assertSetEqual(c.requires, {'d', 'b', 'c'})
        self.assertSetEqual(c.destroys, set())

    def test_require_in(self):
        """ Test requires for out(c), a instruction
        """
        c = memcell.MemCell('in a, (c)', 1)
        self.assertSetEqual(c.requires, {'b', 'c'})
        self.assertSetEqual(c.destroys, {'a'})

        c = memcell.MemCell('in d, (c)', 1)
        self.assertSetEqual(c.requires, {'b', 'c'})
        self.assertSetEqual(c.destroys, {'d'})

    def test_require_ld_NN_a(self):
        """ Test requires for ld (NN), a instruction
        """
        c = memcell.MemCell('ld (_push), a', 1)
        self.assertSetEqual(c.requires, {'a'})
        self.assertSetEqual(c.destroys, set())
