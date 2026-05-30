# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.outfmt.sna import SnaEmitter


def test_sna_emitter_generate():
    emitter = SnaEmitter()
    program_bytes = b"\x00" * 100
    entry_point = 0x8000

    # generate(self, loader_bytes, clear_addr, entry_point, program_bytes)
    # SnaEmitter.emit calls generate(None, entry_point - 1, entry_point, program_bytes)
    sna_data = emitter.generate(None, entry_point - 1, entry_point, program_bytes)

    assert len(sna_data) == 27 + 49152

    # Check some header values
    # snapshot.I is initialized to 0x3F in GenSnapshot
    assert sna_data[0] == 0x3F

    # Border color (snapshot.outFE & 7)
    # GenSnapshot.outFE = 0x0F, so 0x0F & 7 = 7
    assert sna_data[26] == 7

    # Check SP
    # GenSnapshot: SP = clear_addr - 3 = (0x8000 - 1) - 3 = 0x7FFC = 32764
    # SnaEmitter: SP = snapshot.SP - 2 = 32764 - 2 = 32762 (0x7FFA)
    # sna_data[23] = 0xFA, sna_data[24] = 0x7F
    assert sna_data[23] == 0xFA
    assert sna_data[24] == 0x7F

    # Check PC patched on stack
    # snapshot.PCL = 0x9E, snapshot.PCH = 0x1B
    # Index in sna_data = 27 + 32762 - 16384 = 16405
    assert sna_data[27 + 32762 - 16384] == 0x9E
    assert sna_data[27 + 32762 - 16384 + 1] == 0x1B


def test_sna_emitter_emit(tmp_path):
    output_file = tmp_path / "test.sna"
    emitter = SnaEmitter()
    emitter.emit(
        output_filename=str(output_file),
        program_name="test",
        loader_bytes=None,
        entry_point=0x8000,
        program_bytes=b"\x00" * 100,
        aux_bin_blocks=[],
        aux_headless_bin_blocks=[],
    )
    assert output_file.exists()
    assert len(output_file.read_bytes()) == 27 + 49152
