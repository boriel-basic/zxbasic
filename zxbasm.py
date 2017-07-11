#!/usr/bin/env python
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

import sys
import os
from optparse import OptionParser

import asmparse
from asmparse import Asm, Expr, Container
import zxbpp

from api.config import OPTIONS

# Release version
VERSION = '1.10'


def main():
    # Create default options
    OPTIONS.add_option_if_not_defined('optimization', int, 0)

    # Create option parser
    o_parser = OptionParser(usage='Usage: %prog <input file> [options]',
                            version='%prog ' + VERSION)

    o_parser.add_option("-d", "--debug",
                        action="count", dest="debug", default=OPTIONS.Debug.value,
                        help="Enable verbosity/debugging output")

    o_parser.add_option("-O", "--optimize", type="int", dest="optimization_level",
                        help="Sets optimization level. 0 = None", default=OPTIONS.optimization.value)

    o_parser.add_option("-o", "--output", type="string", dest="output_file",
                        help="Sets output file. Default is input filename with .bin extension", default=None)

    o_parser.add_option("-T", "--tzx", action="store_true", dest="tzx", default=False,
                        help="Sets output format to tzx (default is .bin)")

    o_parser.add_option("-t", "--tap", action="store_true", dest="tap", default=False,
                        help="Sets output format to tzx (default is .bin)")

    o_parser.add_option("-B", "--BASIC", action="store_true", dest="basic", default=False,
                        help="Creates a BASIC loader which load the rest of the CODE. Requires -T ot -t")

    o_parser.add_option("-a", "--autorun", action="store_true", dest="autorun", default=False,
                        help="Sets the program to auto run once loaded (implies --BASIC)")

    o_parser.add_option("-e", "--errmsg", type="string", dest="stderr", default=OPTIONS.StdErrFileName.value,
                        help="Error messages file (standard error console by default")

    o_parser.add_option("-M", "--mmap", type="string", dest="memory_map", default=None,
                        help="Generate label memory map")

    o_parser.add_option("-b", "--bracket", action="store_true", dest="bracket", default=False,
                        help="Allows brackets only for memory access and indirections")

    (options, args) = o_parser.parse_args()

    if len(args) != 1:
        o_parser.error("missing input file. (Try -h)")
        sys.exit(3)

    if not os.path.exists(args[0]):
        o_parser.error("No such file or directory: '%s'" % args[0])
        sys.exit(2)

    OPTIONS.Debug.value = int(options.debug)
    OPTIONS.inputFileName.value = args[0]
    OPTIONS.outputFileName.value = options.output_file
    OPTIONS.optimization.value = options.optimization_level
    OPTIONS.use_loader.value = options.autorun or options.basic
    OPTIONS.autorun.value = options.autorun
    OPTIONS.StdErrFileName.value = options.stderr
    OPTIONS.memory_map.value = options.memory_map
    OPTIONS.bracket.value = options.bracket

    if options.tzx:
        OPTIONS.output_file_type.value = 'tzx'
    elif options.tap:
        OPTIONS.output_file_type.value = 'tap'

    if not OPTIONS.outputFileName.value:
        OPTIONS.outputFileName.value = os.path.splitext(
            os.path.basename(OPTIONS.inputFileName.value))[0] + os.path.extsep + OPTIONS.output_file_type.value

    if OPTIONS.StdErrFileName.value:
        OPTIONS.stderr.value = open(OPTIONS.StdErrFileName.value, 'wt')

    if int(options.tzx) + int(options.tap) > 1:
        o_parser.error("Options --tap, --tzx and --asm are mutually exclusive")
        sys.exit(3)

    if OPTIONS.use_loader.value and not options.tzx and not options.tap:
        o_parser.error('Option --BASIC and --autorun requires --tzx or tap format')
        sys.exit(4)

    # Configure the preprocessor to use the asm-preprocessor-lexer
    zxbpp.setMode('asm')

    # Now filter them against the preprocessor
    zxbpp.main([OPTIONS.inputFileName.value])

    # Now output the result
    asm_output = zxbpp.OUTPUT
    asmparse.assemble(asm_output)
    if not asmparse.MEMORY.memory_bytes:  # empty seq.
        asmparse.warning(0, "Nothing to assemble. Exiting...")
        sys.exit(0)

    current_org = max(asmparse.MEMORY.memory_bytes.keys() or [0]) + 1

    for label, line in asmparse.INITS:
        expr_label = Expr.makenode(Container(asmparse.MEMORY.get_label(label, line), line))
        asmparse.MEMORY.add_instruction(Asm(0, 'CALL NN', expr_label))

    if len(asmparse.INITS) > 0:
        if asmparse.AUTORUN_ADDR is not None:
            asmparse.MEMORY.add_instruction(Asm(0, 'JP NN', asmparse.AUTORUN_ADDR))
        else:
            asmparse.MEMORY.add_instruction(
                Asm(0, 'JP NN', min(asmparse.MEMORY.orgs.keys())))  # To the beginning of binary. Ehem...

        asmparse.AUTORUN_ADDR = current_org

    if OPTIONS.memory_map.value:
        with open(OPTIONS.memory_map.value, 'wt') as f:
            f.write(asmparse.MEMORY.memory_map)

    asmparse.generate_binary(OPTIONS.outputFileName.value, OPTIONS.output_file_type.value)


if __name__ == '__main__':
    main()
