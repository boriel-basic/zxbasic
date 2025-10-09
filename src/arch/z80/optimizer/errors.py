# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.api.exception import Error


class DuplicatedLabelError(Error):
    """Exception raised when a duplicated Label is found.
    This should never happen.
    """

    def __init__(self, label):
        Error.__init__(self, f"Duplicated label '{label}'")
        self.label = label


class OptimizerError(Error):
    """Generic exception raised during the optimization phase"""

    def __init__(self, msg):
        Error.__init__(self, msg)


class OptimizerInvalidBasicBlockError(OptimizerError):
    """Exception raised when a block is not correctly partitioned.
    This should never happen.
    """

    def __init__(self, block):
        Error.__init__(self, f"Invalid block '{block.id}'")
        self.block = block
