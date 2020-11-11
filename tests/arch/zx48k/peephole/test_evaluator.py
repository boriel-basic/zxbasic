# -*- coding: utf-8 -*-

import unittest

from src.arch.zx48k.peephole import evaluator


class TestEvaluator(unittest.TestCase):
    def test_value(self):
        assert evaluator.Evaluator(['x']).eval() == 'x'

    def test_op_not(self):
        not_ = evaluator.OP_NOT
        assert evaluator.Evaluator([not_, '']).eval()
        assert not evaluator.Evaluator([not_, [not_, '']]).eval()

    def test_op_plus(self):
        plus_ = evaluator.OP_PLUS
        assert evaluator.Evaluator(['a', plus_, 'b']).eval() == 'ab'

    def test_op_eq(self):
        eq_ = evaluator.OP_EQ
        assert evaluator.Evaluator(['a', eq_, 'a']).eval()
        assert not evaluator.Evaluator(['a', eq_, 'b']).eval()

    def test_op_neq(self):
        neq_ = evaluator.OP_NE
        assert evaluator.Evaluator(['a', neq_, 'b']).eval()
        assert not evaluator.Evaluator(['a', neq_, 'a']).eval()

    def test_op_or(self):
        or_ = evaluator.OP_OR
        assert not evaluator.Evaluator([False, or_, False]).eval()
        assert evaluator.Evaluator([False, or_, True]).eval()
        assert evaluator.Evaluator([True, or_, False]).eval()
        assert evaluator.Evaluator([True, or_, True]).eval()

    def test_op_and(self):
        and_ = evaluator.OP_AND
        assert not evaluator.Evaluator([False, and_, False]).eval()
        assert not evaluator.Evaluator([False, and_, True]).eval()
        assert not evaluator.Evaluator([True, and_, False]).eval()
        assert evaluator.Evaluator([True, and_, True]).eval()
