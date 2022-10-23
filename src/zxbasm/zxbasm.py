#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
#
# This is the Parser for the ZXBASM (ZXBasic Assembler)
# ----------------------------------------------------------------------

import argparse
import os
import sys

import src.api.config
from src.api import errmsg, global_
from src.api.config import OPTIONS
from src.zxbasm import asmparse, expr
from src.zxbasm.version import VERSION
from src.zxbpp import zxbpp


def main(args=None):
    # Initializes asm parser state
    src.api.config.init()
    asmparse.init()
    zxbpp.init()

    # Create option parser
    o_parser = argparse.ArgumentParser()
    o_parser.add_argument("PROGRAM", type=str, help="ASM program file")
    o_parser.add_argument(
        "-d", "--debug", action="count", default=OPTIONS.debug_level, help="Enable verbosity/debugging output"
    )

    o_parser.add_argument(
        "-O",
        "--optimize",
        type=int,
        dest="optimization_level",
        help="Sets optimization level. 0 = None",
        default=OPTIONS.optimization_level,
    )

    o_parser.add_argument(
        "-o",
        "--output",
        type=str,
        dest="output_file",
        help="Sets output file. Default is input filename with .bin extension",
        default=None,
    )

    o_parser.add_argument(
        "-T",
        "--tzx",
        action="store_true",
        dest="tzx",
        default=False,
        help="Sets output format to tzx (default is .bin)",
    )

    o_parser.add_argument(
        "-t",
        "--tap",
        action="store_true",
        dest="tap",
        default=False,
        help="Sets output format to tzx (default is .bin)",
    )

    o_parser.add_argument(
        "-B",
        "--BASIC",
        action="store_true",
        dest="basic",
        default=False,
        help="Creates a BASIC loader which load the rest of the CODE. Requires -T ot -t",
    )

    o_parser.add_argument(
        "-a",
        "--autorun",
        action="store_true",
        default=False,
        help="Sets the program to auto run once loaded (implies --BASIC)",
    )

    o_parser.add_argument(
        "-e",
        "--errmsg",
        type=str,
        dest="stderr",
        default=OPTIONS.stderr_filename,
        help="Error messages file (standard error console by default",
    )

    o_parser.add_argument("-M", "--mmap", type=str, dest="memory_map", default=None, help="Generate label memory map")

    o_parser.add_argument(
        "-b",
        "--bracket",
        action="store_true",
        default=False,
        help="Allows brackets only for memory access and indirections",
    )

    o_parser.add_argument(
        "-N", "--zxnext", action="store_true", default=False, help="Enable ZX Next extra ASM opcodes!"
    )

    o_parser.add_argument("--version", action="version", version="%(prog)s " + VERSION)

    options = o_parser.parse_args(args)

    if not os.path.exists(options.PROGRAM):
        o_parser.error("No such file or directory: '%s'" % options.PROGRAM)
        sys.exit(2)

    OPTIONS.debug_level = int(options.debug)
    OPTIONS.input_filename = options.PROGRAM
    OPTIONS.output_filename = options.output_file
    OPTIONS.optimization_level = options.optimization_level
    OPTIONS.use_basic_loader = options.autorun or options.basic
    OPTIONS.autorun = options.autorun
    OPTIONS.stderr_filename = options.stderr
    OPTIONS.memory_map = options.memory_map
    OPTIONS.force_asm_brackets = options.bracket
    OPTIONS.zxnext = options.zxnext

    if options.tzx:
        OPTIONS.output_file_type = "tzx"
    elif options.tap:
        OPTIONS.output_file_type = "tap"

    if not OPTIONS.output_filename:
        OPTIONS.output_filename = (
            os.path.splitext(os.path.basename(OPTIONS.input_filename))[0] + os.path.extsep + OPTIONS.output_file_type
        )

    if OPTIONS.stderr_filename:
        OPTIONS.stderr = open(OPTIONS.stderr_filename, "wt")

    if int(options.tzx) + int(options.tap) > 1:
        o_parser.error("Options --tap, --tzx and --asm are mutually exclusive")
        return 3

    if OPTIONS.use_basic_loader and not options.tzx and not options.tap:
        o_parser.error("Option --BASIC and --autorun requires --tzx or tap format")
        return 4

    # Configure the preprocessor to use the asm-preprocessor-lexer
    zxbpp.setMode("asm")

    # Now filter them against the preprocessor
    zxbpp.main([OPTIONS.input_filename])

    # Now output the result
    asm_output = zxbpp.OUTPUT
    asmparse.assemble(asm_output)
    if global_.has_errors:
        return 1

    if not asmparse.MEMORY.memory_bytes:  # empty seq.
        errmsg.warning(0, "Nothing to assemble. Exiting...")
        return 0

    current_org = max(asmparse.MEMORY.memory_bytes.keys() or [0]) + 1

    for label, line in asmparse.INITS:
        expr_label = expr.Expr.makenode(asmparse.Container(asmparse.MEMORY.get_label(label, line), line))
        asmparse.MEMORY.add_instruction(asmparse.Asm(0, "CALL NN", expr_label))

    if len(asmparse.INITS) > 0:
        if asmparse.AUTORUN_ADDR is not None:
            asmparse.MEMORY.add_instruction(asmparse.Asm(0, "JP NN", asmparse.AUTORUN_ADDR))
        else:
            asmparse.MEMORY.add_instruction(
                asmparse.Asm(0, "JP NN", min(asmparse.MEMORY.orgs.keys()))
            )  # To the beginning of binary

        asmparse.AUTORUN_ADDR = current_org

    if OPTIONS.memory_map:
        with open(OPTIONS.memory_map, "wt") as f:
            f.write(asmparse.MEMORY.memory_map)

    asmparse.generate_binary(OPTIONS.output_filename, OPTIONS.output_file_type)
    return global_.has_errors


if __name__ == "__main__":
    sys.exit(main())
