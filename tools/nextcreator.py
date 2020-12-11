#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from typing import List
import argparse
import os
import re

CORE_MAJOR = 0
CORE_MINOR = 1
CORE_SUBMINOR = 2

line_num = 0
file_count = 0
current_bank = 0
current_address = 0
last_bank = -1
filelen = None
file_added: bool = False
palcnt = None
VERSION_DECIMAL = 11

palette: bytearray = bytearray(256 * 2)
loading: bytearray = bytearray(49152)
loading_ULA: bytearray = bytearray(6144 + 768 + 256)
palette_LoRes: bytearray = bytearray(256 * 2)
loading_LoRes: bytearray = bytearray(6144 + 6144)
loading_HiRes: bytearray = bytearray(6144 + 6144 + 768 + 256)
loading_HiCol: bytearray = bytearray(6144 + 6144)

hires_colour = 0
bigFile: bytearray = bytearray(1024 ** 3)


class LoadingScreen:
    LAYER2 = 1
    ULA_LOADING = 2
    LO_RES = 4
    HI_RES = 8
    HI_COLOUR = 16


def to_bin(bits: int, num: int) -> bytes:
    num &= ((1 << bits) - 1)
    result = bytearray()
    for i in range(bits >> 3):
        result.append(num & 0xFF)
        num >>= 8

    return bytes(result)


def to_byte(num: int) -> bytes:
    return to_bin(8, num)


def to_short(num: int) -> bytes:
    return to_bin(16, num)


def to_u32(num: int) -> bytes:
    return to_bin(32, num)


def pad(b: bytes, n: int) -> bytes:
    return (b + b'\0' * n)[:n]


class Header:
    """ ZX Next NEX header definition
    """

    def __init__(self):
        self.next: bytes = b'Next'
        self.version_number: bytes = b'V1.1'
        self.RAM_required = 0
        self.num_banks_to_load = 0
        self.loading_screen = 0
        self.border_color = 0
        self.SP = 0
        self.PC = 0
        self.num_extra_files = 0
        self.banks: List[int] = [0] * 112
        self.loading_bar = 0
        self.loading_color = 0
        self.loading_bank_delay = 0
        self.loaded_delay = 0
        self.dont_reset_regs = 0
        self.core_required = b'\x00\x00\x00'
        self.hi_res_colors = 0
        self.entry_bank = 0

    def as_binary(self) -> bytes:
        result = bytearray()
        for chunk in [
            pad(self.next, 4),
            pad(self.version_number, 4),
            to_byte(self.RAM_required),
            to_byte(self.num_banks_to_load),
            to_byte(self.loading_screen),
            to_byte(self.border_color),
            to_short(self.SP),
            to_short(self.PC),
            to_short(self.num_extra_files),
            self.banks,
            to_byte(self.loading_bar),
            to_byte(self.loading_color),
            to_byte(self.loading_bank_delay),
            to_byte(self.loaded_delay),
            to_byte(self.dont_reset_regs),
            pad(self.core_required, 3),
            to_byte(self.hi_res_colors),
            to_byte(self.entry_bank)
        ]:
            result.extend(chunk)

        return pad(result, 512)


HEADER512 = Header()


def get_real_bank(bank: int) -> int:
    if bank > 7:
        return bank

    return [2, 3, 1, 4, 5, 0, 6, 7][bank]


def get_bank_order(bank: int) -> int:
    if bank > 7:
        return bank

    return [5, 2, 0, 1, 3, 4, 6, 7][bank]


def get_next_bank(bank: int) -> int:
    if bank > 7:
        return bank + 1

    return [1, 3, 0, 4, 6, 2, 7, 8][bank]


def make_num(*nums) -> int:
    result = 0
    acc = 1

    for n in nums:
        result += n * acc
        acc <<= 8

    return result


def normalize_path_name(path: str) -> str:
    if path == os.path.join(*os.path.split(os.path.sep)):
        return path

    return os.path.join(*re.compile(r'[\\/]').split(path))


def parse_int(string: str) -> int:
    string = string.strip()

    if string.startswith('$'):
        return int(string[1:], 16)

    if string.lower().endswith('h'):
        return int(string[:-1], 16)

    return int(string)


def add_file(fname: str, bank=None, address=None, *SNA_Bank):
    global current_bank, last_bank, current_address

    if len(fname) < 4:
        raise Exception(f'Wrong filename "{fname}" at line {line_num}')

    current_bank = int(bank) if bank is not None else current_bank
    current_address = parse_int(address) if address is not None else current_address
    SNA_Header: bytearray
    SNA128_Header: bytearray

    path = normalize_path_name(fname)
    dirname = os.path.dirname(path)
    basename = os.path.basename(path)
    filenames = {x.lower(): x for x in os.listdir()}
    basename = filenames.get(basename, basename)
    final_path = os.path.join(dirname, basename)

    with open(final_path, 'rb') as fin:
        sna = fname.endswith('sna')
        if sna:
            SNA_Header = bytearray(fin.read(27))
            current_bank = 5
            current_address = 0x4000
            if len(SNA_Bank) != 8:
                raise Exception('Wrong sna banks')

            SNA_Bank = tuple(int(x) for x in SNA_Bank)

        while True:
            real_bank = get_real_bank(current_bank)
            offset = real_bank * 16384 + (current_address & 0x3fff)
            length = 0x4000 - (current_address & 0x3fff)
            buf = fin.read(length)

            if not len(buf):
                break

            length = len(buf)
            bigFile[offset: offset + length] = buf

            if current_bank < 64 + 48:
                HEADER512.banks[current_bank] = 1

            if sna and not SNA_Bank[real_bank]:
                HEADER512.banks[current_bank] = 0
                print("Skipping SNA bank %d" % current_bank)
            else:
                print("bank=%d,addr=%04x,realbank=%d,%d" % (current_bank, current_address, real_bank, length))

            if real_bank > last_bank:
                last_bank = real_bank

            if sna:
                if current_bank == 0:
                    SNA128_Header = bytearray(fin.read(4))
                    print("128KHeader len = %d" % len(SNA128_Header))
                    sp = make_num(*SNA_Header[23:25])
                    if not SNA128_Header:
                        SNA128_Header = bytearray([0] * 4)
                        sp2 = sp
                        if sp2 >= 16384:
                            sp2 -= 16384
                        SNA128_Header[0] = bigFile[sp2 + 16]
                        SNA128_Header[1] = bigFile[sp2 + 17]
                        SNA128_Header[2] = 0
                        SNA128_Header[3] = 0

                    HEADER512.SP = sp
                    HEADER512.PC = make_num(*SNA128_Header[0:2])
                    print("SP=%04x,PC=%04x" % (HEADER512.SP, HEADER512.PC))

            current_address = ((current_address & 0xc000) + 0x4000) & 0xc000
            current_bank = get_next_bank(current_bank)


def convert_8bit_to_32bit(v: int) -> int:
    if v > 255:
        return 255
    return v >> 5


def get_palette_value(r: int, g: int, b: int) -> int:
    return ((convert_8bit_to_32bit(r) >> 2) & 1 << 8) + \
           (convert_8bit_to_32bit(r) >> 1) + (convert_8bit_to_32bit(g) << 2) + \
           (convert_8bit_to_32bit(b) << 5)


def load_bmp(filename, use_8bit_palette: bool, dont_save_palette: int, border=None, bar1=None, bar2=None, delay1=None,
             delay2=None):
    global file_added, palette

    with open(filename, 'rb') as f:
        temp_header = f.read(0x36)
        temp_palette = f.read(4 * 256)

        palette = bytearray([x for int16 in [get_palette_value(
            temp_palette[i * 4],
            temp_palette[i * 4 + 1],
            temp_palette[i * 4 + 2])
            for i in range(256)] for x in (int16 & 0xFF, int16 >> 8)])

        if use_8bit_palette:
            palette = bytearray([x & 0xFF for x in palette])

        i = make_num(*temp_header[10:12])
        f.seek(i)
        for i in range(192):
            if temp_header[25] < 128:
                offset = 256 * (191 - i)
            else:
                offset = 256 * i
            loading[offset: offset + 256] = f.read(256)

    HEADER512.loading_screen |= LoadingScreen.LAYER2 + 128 * dont_save_palette
    print(f"Loading Screen '{filename}'")
    file_added = True

    if border is not None:
        HEADER512.border_color = int(border)

    if bar1 is not None:
        HEADER512.loading_bar = int(bar1)

    if bar2 is not None:
        HEADER512.loading_color = int(bar2)

    if delay1 is not None:
        HEADER512.loading_bank_delay = int(delay1)

    if delay2 is not None:
        HEADER512.loaded_delay = int(delay2)


def load_scr(filename: str):
    global file_added

    try:
        with open(filename, 'rb') as f:
            loading_ULA[:] = f.read(6144 + 768)
        HEADER512.loading_screen |= LoadingScreen.ULA_LOADING
        print(f"Loading Screen '{filename}'")
        file_added = True
    except FileNotFoundError:
        print(f"Can't find file '{filename}")


def load_slr(filename: str):
    global file_added, palette_LoRes

    try:
        with open(filename, 'rb') as f:
            temp_header = f.read(0x36)
            temp_palette = f.read(4 * 256)
            loading_ULA[:] = f.read(6144 + 768)
            palette_LoRes = bytearray([x for int16 in [
                get_palette_value(temp_palette[i * 4], temp_palette[i * 4 + 1], temp_palette[i * 4 + 2])
                for i in range(256)] for x in (int16 & 0xFF, int16 >> 8)])

            i = make_num(*temp_header[10:12])
            f.seek(i)
            for i in range(96):
                if temp_header[25] < 128:
                    offset = 128 * (95 - i)
                else:
                    offset = 128 * i
                loading_HiRes[offset: offset + 128] = f.read(128)

        HEADER512.loading_screen |= LoadingScreen.LO_RES
        print(f"Loading Screen '{filename}'")
        file_added = True
    except FileNotFoundError:
        print(f"Can't find file '{filename}")


def load_shr(filename: str, hires_colour=None):
    global loading_HiRes, file_added

    try:
        with open(filename, "rb") as f:
            loading_HiRes = bytearray(f.read(6144))
        print(f"Loading Screen '{filename}'")
    except FileNotFoundError:
        print(f"Can't find file '{filename}")

    HEADER512.loading_screen |= LoadingScreen.HI_RES
    file_added = True
    if hires_colour is not None:
        HEADER512.hires_colour = int(hires_colour)


def load_shc(filename: str):
    global loading_HiCol, file_added

    try:
        with open(filename, "rb") as f:
            loading_HiCol = bytearray(f.read(6144 * 2))
        print(f"Loading Screen '{filename}'")
        HEADER512.loading_screen |= LoadingScreen.HI_COLOUR
        file_added = True
    except FileNotFoundError:
        print(f"Can't find file '{filename}")


def set_entry_bank(bank):
    global VERSION_DECIMAL

    HEADER512.entry_bank = int(bank)
    if HEADER512.entry_bank > 0 and VERSION_DECIMAL < 12:
        VERSION_DECIMAL = 12
        HEADER512.version_number = b'V1.2'
        print(f'Entry Bank={HEADER512.entry_bank}')


def set_PCSP(PC, SP=None, entry_bank=None):
    global VERSION_DECIMAL

    HEADER512.PC = parse_int(PC)
    print("PC=$%04x" % HEADER512.PC)

    if SP is not None:
        HEADER512.SP = parse_int(SP)
        print("SP=$%04x" % HEADER512.SP)

    if entry_bank is not None:
        set_entry_bank(entry_bank)


def load_mmu(filename: str, bank8k=None, address8k=None):
    global current_bank, current_address

    if bank8k is not None:
        bank8k = int(bank8k)
        current_bank = (bank8k >> 1)

    if address8k is not None:
        current_address = address8k = parse_int(address8k)
        if bank8k != (current_bank << 1):
            current_address += 0x2000

    print(f"File '{filename}' 8K bank {bank8k}, {'%04x' % address8k} "
          f"(16K bank {current_bank}, {'%04x' % current_address})")
    add_file(filename)


def parse_file(fname: str):
    global line_num, current_bank, current_address, hires_colour, VERSION_DECIMAL

    line_num = 0
    current_bank = 0
    current_address = 0

    with open(fname, 'rt', encoding='utf-8') as fin:
        for line in fin:
            line_num += 1
            line = line.strip()
            if not line or line.startswith(';'):
                continue

            if not line.startswith('!'):
                add_file(*(x.strip() for x in line.split(',')))

            elif line.startswith('!COR'):
                HEADER512.core_required = bytes([int(x) for x in line[4:].split(',')])
                print("Requires Core %d.%d.%d or greater" % (
                    HEADER512.core_required[CORE_MAJOR],
                    HEADER512.core_required[CORE_MINOR],
                    HEADER512.core_required[CORE_SUBMINOR])
                )

            elif line.startswith('!BMP'):
                line = line[4:]
                dont_save_palette = 0
                use_8bit_palette = False

                if line[0] == ',':
                    hires_colour = int(line[1:])  # Not used later?
                else:
                    if line[0] == '!':
                        dont_save_palette = 1
                        line = line[1:]
                    if line[0] == '8':
                        use_8bit_palette = True
                        line = line[1:]
                        if line[0] == ',':
                            line = line[1:]

                    filename, *params = line.split(',')
                    load_bmp(filename, use_8bit_palette, dont_save_palette, *params)

            elif line.startswith('!SCR'):
                load_scr(line[4:])

            elif line.startswith('!SLR'):
                load_slr(line[4:])

            elif line.startswith('!SHR'):
                load_shr(*line[4:].split(','))

            elif line.startswith('!SHC'):
                load_shc(line[4:])

            elif line.startswith('!PCSP'):
                set_PCSP(*line[5:].split(','))

            elif line.startswith('!MMU'):
                load_mmu(*line[4:].split(','))

            elif line.startswith('!BANK'):
                set_entry_bank(line[5:])


def generate_file(filename: str):
    if last_bank <= -1 and not file_added:
        return

    print(f"Generating NEX file in {HEADER512.version_number.decode('utf-8')} format")
    HEADER512.num_banks_to_load = sum(int(HEADER512.banks[i] > 0) for i in range(112))
    HEADER512.RAM_required = int(HEADER512.num_banks_to_load >= 8)
    print(f"Generating NEX file for {HEADER512.RAM_required + 1}MB machine")

    filename_path = normalize_path_name(filename)
    try:
        with open(filename_path, 'wb') as f:
            f.write(HEADER512.as_binary())
            if HEADER512.loading_screen:
                if HEADER512.loading_screen & LoadingScreen.LAYER2:
                    if not HEADER512.loading_screen & 128:
                        f.write(palette)
                    f.write(loading)

                if HEADER512.loading_screen & LoadingScreen.ULA_LOADING:
                    f.write(loading_ULA)

                if HEADER512.loading_screen & LoadingScreen.LO_RES:
                    if not HEADER512.loading_screen & 128:
                        f.write(palette_LoRes)
                    f.write(loading_LoRes)

                if HEADER512.loading_screen & LoadingScreen.HI_RES:
                    f.write(loading_HiRes)

                if HEADER512.loading_screen & LoadingScreen.HI_COLOUR:
                    f.write(loading_HiCol)

            for i in range(112):
                if HEADER512.banks[get_bank_order(i)]:
                    f.write(bigFile[i * 16384: (i + 1) * 16384])

    except IOError:
        print(f"Can't open file '{filename}'. Nothing output")
        sys.exit(1)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('FILEIN', type=str, help="Input filename")
    parser.add_argument('FILEOUT', type=str, help='Output filename')

    options = parser.parse_args()
    parse_file(options.FILEIN)
    generate_file(options.FILEOUT)
