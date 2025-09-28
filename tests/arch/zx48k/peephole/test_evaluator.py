# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import unittest

from src.arch.z80.peephole import evaluator


class TestEvaluator(unittest.TestCase):
    def test_value(self):
        assert evaluator.Evaluator(["x"]).eval() == "x"

    def test_op_not(self):
        not_ = evaluator.FN.OP_NOT
        assert evaluator.Evaluator([not_, ""]).eval()
        assert not evaluator.Evaluator([not_, [not_, ""]]).eval()

    def test_op_plus(self):
        plus_ = evaluator.FN.OP_PLUS
        assert evaluator.Evaluator(["a", plus_, "b"]).eval() == "ab"

    def test_op_eq(self):
        eq_ = evaluator.FN.OP_EQ
        assert evaluator.Evaluator(["a", eq_, "a"]).eval()
        assert not evaluator.Evaluator(["a", eq_, "b"]).eval()

    def test_op_neq(self):
        neq_ = evaluator.FN.OP_NE
        assert evaluator.Evaluator(["a", neq_, "b"]).eval()
        assert not evaluator.Evaluator(["a", neq_, "a"]).eval()

    def test_op_or(self):
        or_ = evaluator.FN.OP_OR
        assert not evaluator.Evaluator([False, or_, False]).eval()
        assert evaluator.Evaluator([False, or_, True]).eval()
        assert evaluator.Evaluator([True, or_, False]).eval()
        assert evaluator.Evaluator([True, or_, True]).eval()

    def test_op_and(self):
        and_ = evaluator.FN.OP_AND
        assert not evaluator.Evaluator([False, and_, False]).eval()
        assert not evaluator.Evaluator([False, and_, True]).eval()
        assert not evaluator.Evaluator([True, and_, False]).eval()
        assert evaluator.Evaluator([True, and_, True]).eval()
