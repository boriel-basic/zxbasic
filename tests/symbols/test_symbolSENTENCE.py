# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from unittest import TestCase

from src.symbols import sym


class TestSymbolSENTENCE(TestCase):
    def setUp(self):
        self.TOKEN = "TOKEN"

    def test_args(self):
        # Must allow None args (which will be ignored)
        s = sym.SENTENCE(
            1, "filename.bas", self.TOKEN, None, None, sym.SENTENCE(2, "another_file.bas", self.TOKEN), None
        )
        self.assertEqual(len(s.args), 1)

    def test_args_fail(self):
        # Fails for non symbol args
        self.assertRaises(AssertionError, sym.SENTENCE, 1, "filename.bas", self.TOKEN, "blah")

    def test_token(self):
        s = sym.SENTENCE(1, "filename.bas", self.TOKEN)
        self.assertEqual(s.token, self.TOKEN)
