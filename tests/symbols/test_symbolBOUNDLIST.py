from unittest import TestCase

from src.symbols import sym


class TestSymbolBOUNDLIST(TestCase):
    def test_make_node(self):
        l1 = 1
        l2 = 2
        l3 = 3
        l4 = 4
        b = sym.BOUND(l1, l2)
        c = sym.BOUND(l3, l4)
        sym.BOUNDLIST.make_node(None, b, c)

    def test__str__(self):
        l1 = 1
        l2 = 2
        l3 = 3
        l4 = 4
        b = sym.BOUND(l1, l2)
        c = sym.BOUND(l3, l4)
        a = sym.BOUNDLIST.make_node(None, b, c)
        self.assertEqual(str(a), f"(({l1} TO {l2}), ({l3} TO {l4}))")

    def test__len__(self):
        l1 = 1
        l2 = 2
        l3 = 3
        l4 = 4
        b = sym.BOUND(l1, l2)
        c = sym.BOUND(l3, l4)
        a = sym.BOUNDLIST(b, c)
        self.assertEqual(len(a), 2)
