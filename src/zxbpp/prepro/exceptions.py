# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------


class PreprocError(Exception):
    """Denotes an exception in the preprocessor"""

    def __init__(self, msg, lineno):
        self.message = msg
        self.lineno = lineno

    def __str__(self):
        return self.message
