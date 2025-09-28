# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import unittest

from src.arch.z80.peephole import template


class TestLineTemplate(unittest.TestCase):
    def test_match_vars(self):
        tpl = template.LineTemplate("push $1")
        output = tpl.filter({"$1": "af", "$2": "anything"})
        self.assertEqual(output, "push af")

    def test_match_vars_unbound_error(self):
        tpl = template.LineTemplate("push $1")
        self.assertRaises(template.UnboundVarError, tpl.filter, ({"$2": "af"}))


class TestBlockTemplate(unittest.TestCase):
    def test_match_vars_several(self):
        tpl = template.BlockTemplate(["push $1", "pop $2"])
        output = tpl.filter({"$1": "af", "$2": "bc"})
        self.assertEqual(output, ["push af", "pop bc"])

    def test_match_vars_unbound_error(self):
        tpl = template.BlockTemplate(["push $1", "pop $2"])
        self.assertRaises(template.UnboundVarError, tpl.filter, ({"$2": "af"}))
