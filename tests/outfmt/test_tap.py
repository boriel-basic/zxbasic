# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.outfmt.tap import TAP


def test_tap_init():
    tap = TAP()
    assert tap.output == b""


def test_tap_standard_block():
    tap = TAP()
    tap.standard_block(b"\x01\x02")
    # Length (3 -> [0x03, 0x00])
    # Data: \x01\x02
    # Checksum: 0x01 ^ 0x02 = 0x03
    assert tap.output == b"\x03\x00\x01\x02\x03"


def test_tap_emit(tmp_path):
    output_file = tmp_path / "test.tap"
    tap = TAP()
    program_bytes = b"\x00\x01"
    tap.emit(
        output_filename=str(output_file),
        program_name="test",
        loader_bytes=None,
        entry_point=16384,
        program_bytes=program_bytes,
        aux_bin_blocks=[],
        aux_headless_bin_blocks=[],
    )
    assert output_file.exists()
    content = output_file.read_bytes()

    # Header block
    # 0x13 0x00 (Length)
    # 0x00 (BLOCK_TYPE_HEADER)
    # 0x03 (HEADER_TYPE_CODE)
    # "test      " (10 bytes)
    # 0x02 0x00 (Length 2)
    # 0x00 0x40 (Address 16384)
    # 0x00 0x80 (32768)
    # Checksum
    expected_header_content = b"\x00\x03test      \x02\x00\x00\x40\x00\x80"
    checksum = 0
    for b in expected_header_content:
        checksum ^= b
    expected_header = b"\x13\x00" + expected_header_content + bytes([checksum])
    assert content.startswith(expected_header)

    # Data block
    # 0x04 0x00 (Length)
    # 0xFF (BLOCK_TYPE_DATA)
    # 0x00 0x01 (data)
    # Checksum: 0xFF ^ 0x00 ^ 0x01 = 0xFE
    expected_data = b"\x04\x00\xff\x00\x01\xfe"
    assert expected_data in content
