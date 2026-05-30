# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.outfmt.binary import BinaryEmitter


def test_binary_emitter(tmp_path):
    output_file = tmp_path / "test.bin"
    emitter = BinaryEmitter()
    program_bytes = b"\x01\x02\x03\x04"

    emitter.emit(
        output_filename=str(output_file),
        program_name="test",
        loader_bytes=None,
        entry_point=16384,
        program_bytes=program_bytes,
        aux_bin_blocks=[],
        aux_headless_bin_blocks=[],
    )

    assert output_file.exists()
    assert output_file.read_bytes() == program_bytes
