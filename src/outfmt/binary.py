# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from .codeemitter import CodeEmitter


class BinaryEmitter(CodeEmitter):
    """Writes compiled code as raw binary data."""

    def emit(
        self,
        output_filename,
        program_name,
        loader_bytes,
        entry_point,
        program_bytes,
        aux_bin_blocks,
        aux_headless_bin_blocks,
    ):
        """Emits resulting binary file."""
        with open(output_filename, "wb") as f:
            f.write(bytearray(program_bytes))
