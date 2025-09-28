# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from unittest import mock

from src.ply.yacc import LRParser


class TestBuildParsetab:
    @mock.patch("src.api.utils.load_object", return_value=None)
    @mock.patch("src.api.utils.save_object", lambda key, obj: obj)
    def test_build_parsetab(self, mock_load_object):
        from src.zxbc import zxbparser

        parser = zxbparser.parser
        assert isinstance(parser, LRParser), "Could not generate an rparser"

    def test_loads_parsetab(self):
        from src.zxbc import zxbparser

        parser = zxbparser.parser
        assert isinstance(parser, LRParser), "Could not load an rparser"
