# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
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
