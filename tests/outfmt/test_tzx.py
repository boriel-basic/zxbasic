# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.outfmt.tzx import TZX


def test_tzx_init():
    tzx = TZX()
    assert tzx.output == b"ZXTape!\x1a\x01\x15"


def test_tzx_lh():
    tzx = TZX()
    assert tzx.LH(0x1234) == [0x34, 0x12]
    assert tzx.LH(0x00FF) == [0xFF, 0x00]


def test_tzx_standard_block():
    tzx = TZX()
    tzx.output = bytearray()
    tzx.standard_block(b"\x01\x02")
    # BLOCK_STANDARD (0x10)
    # Pause (1000ms -> [0xE8, 0x03])
    # Length (3 -> [0x03, 0x00]) - length of data + 1 for checksum
    # Data: \x01\x02
    # Checksum: 0x01 ^ 0x02 = 0x03
    assert tzx.output == b"\x10\xe8\x03\x03\x00\x01\x02\x03"


def test_tzx_emit(tmp_path):
    output_file = tmp_path / "test.tzx"
    tzx = TZX()
    program_bytes = b"\x00\x01"
    tzx.emit(
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
    assert content.startswith(b"ZXTape!\x1a\x01\x15")

    # Header block for "test"
    # 0x10 (Standard block ID)
    # 0xE8 0x03 (1000ms pause)
    # 0x13 0x00 (Length of header: 1 + 1 + 10 + 2 + 2 + 2 + 1 = 19 -> 0x13)
    # 0x00 (BLOCK_TYPE_HEADER)
    # 0x03 (HEADER_TYPE_CODE)
    # "test      " (10 bytes)
    # 0x02 0x00 (Length 2)
    # 0x00 0x40 (Address 16384)
    # 0x00 0x80 (32768)
    # Checksum (XOR of all bytes in block)
    expected_header_content = b"\x00\x03test      \x02\x00\x00\x40\x00\x80"
    checksum = 0
    for b in expected_header_content:
        checksum ^= b
    expected_header_block = b"\x10\xe8\x03\x13\x00" + expected_header_content + bytes([checksum])
    assert expected_header_block in content

    # Data block
    # 0x10
    # 0xE8 0x03
    # 0x04 0x00 (Length of data: 1 (type) + 2 (bytes) + 1 (checksum) = 4)
    # 0xFF (BLOCK_TYPE_DATA)
    # 0x00 0x01 (data)
    # Checksum: 0xFF ^ 0x00 ^ 0x01 = 0xFE
    expected_data_block = b"\x10\xe8\x03\x04\x00\xff\x00\x01\xfe"
    assert expected_data_block in content
