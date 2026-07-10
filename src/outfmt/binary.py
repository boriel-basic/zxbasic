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
        output_filename: str,
        program_name: str,
        loader_bytes: bytearray | None,
        entry_point: int,
        program_bytes: bytearray | bytes | list[int],
        aux_bin_blocks: list[tuple[str, list[int]]],
        aux_headless_bin_blocks: list[list[int]],
    ):
        """Emits the resulting binary file."""
        with open(output_filename, "wb") as f:
            f.write(bytearray(program_bytes))
