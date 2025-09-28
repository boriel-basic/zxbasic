# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from abc import ABC, abstractmethod


class CodeEmitter(ABC):
    """The base code emission interface."""

    @abstractmethod
    def emit(
        self,
        output_filename: str,
        program_name: str,
        loader_bytes: bytearray,
        entry_point,
        program_bytes,
        aux_bin_blocks,
        aux_headless_bin_blocks,
    ):
        pass
