#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et:

from version import VERSION

import sys
import os
import re
from optparse import OptionParser

from six import StringIO

import api.debug
import api.optimize
import zxblex
import zxbparser
import zxbpp
import asmparse
import backend

from api import global_ as gl
from api.config import OPTIONS
from api import debug
from backend import ASMS
from optimizer import optimize

import arch

zxblex.syntax_error = zxbparser.syntax_error  # Map both functions

# Default parameter values
DEFAULT_OPTIMIZATION_LEVEL = 2  # Optimization level. Higher -> more optimized


def get_inits(memory):
    backend.INITS.union(zxbparser.INITS)

    reinit = re.compile(r'^#[ \t]*init[ \t]+([_a-zA-Z][_a-zA-Z0-9]*)[ \t]*$',
                        re.IGNORECASE)

    i = 0
    for m in memory:
        init = reinit.match(m)
        if init is not None:
            backend.INITS.add(init.groups()[0])
            memory[i] = ''
        i += 1


def output(memory, ofile=None):
    """ Filters the output removing useless preprocessor #directives
    and writes it to the given file or to the screen if no file is passed
    """
    for m in memory:
        if len(m) > 0 and m[0] == '#':  # Preprocessor directive?
            if ofile is None:
                print(m)
            else:
                ofile.write('%s\n' % m)
            continue

        # Prints a 4 spaces "tab" for non labels
        if ':' not in m:
            if ofile is None:
                print('    '),
            else:
                ofile.write('\t')

        if ofile is None:
            print(m)
        else:
            ofile.write('%s\n' % m)


def main():
    """ Entry point when executed from command line.
    You can use zxb.py as a module with import, and this
    function won't be executed.
    """
    OPTIONS.add_option_if_not_defined('memoryCheck', bool, False)
    OPTIONS.add_option_if_not_defined('strictBool', bool, False)
    OPTIONS.add_option_if_not_defined('arrayCheck', bool, False)
    OPTIONS.add_option_if_not_defined('array_base', int, 0)
    OPTIONS.add_option_if_not_defined('string_base', int, 0)
    OPTIONS.add_option_if_not_defined('enableBreak', bool, False)
    OPTIONS.add_option_if_not_defined('emmitBackend', bool, False)
    OPTIONS.add_option_if_not_defined('arch', str, 'zx48k')
    OPTIONS.add_option_if_not_defined('__DEFINES', dict, {})
    OPTIONS.add_option_if_not_defined('explicit', bool, False)

    # ------------------------------------------------------------
    # Command line parsing
    # ------------------------------------------------------------
    parser = OptionParser(usage='Usage: %prog <input file> [options]',
                          version='%prog ' + VERSION)

    parser.add_option("-d", "--debug",
                      action="count", dest="debug", default=OPTIONS.Debug.value,
                      help="Enable verbosity/debugging output. Additional -d increase verbosity/debug level.")

    parser.add_option("-O", "--optimize", type="int", dest="optimization_level",
                      help="Sets optimization level. 0 = None", default=DEFAULT_OPTIMIZATION_LEVEL)

    parser.add_option("-o", "--output", type="string", dest="output_file",
                      help="Sets output file. Default is input filename with .bin extension", default=None)

    parser.add_option("-T", "--tzx", action="store_true", dest="tzx", default=False,
                      help="Sets output format to tzx (default is .bin)")

    parser.add_option("-t", "--tap", action="store_true", dest="tap", default=False,
                      help="Sets output format to tap (default is .bin)")

    parser.add_option("-B", "--BASIC", action="store_true", dest="basic", default=False,
                      help="Creates a BASIC loader which load the rest of the CODE. Requires -T ot -t")

    parser.add_option("-a", "--autorun", action="store_true", dest="autorun", default=False,
                      help="Sets the program to be run once loaded")

    parser.add_option("-A", "--asm", action="store_true", dest="asm", default=False,
                      help="Sets output format to asm")

    parser.add_option("-S", "--org", type="int", dest="org",
                      help="Start of machine code. By default %i" % OPTIONS.org.value, default=OPTIONS.org.value)

    parser.add_option("-e", "--errmsg", type="string", dest="stderr", default=OPTIONS.StdErrFileName.value,
                      help="Error messages file (standard error console by default)")

    parser.add_option("--array-base", type="int", dest="array_base", default=OPTIONS.array_base.value,
                      help="Default lower index for arrays (0 by default)")

    parser.add_option("--string-base", type="int", dest="string_base", default=OPTIONS.string_base.value,
                      help="Default lower index for strings (0 by default)")

    parser.add_option("-Z", "--sinclair", action="store_true", dest="sinclair", default=False,
                      help="Enable by default some more original ZX Spectrum Sinclair BASIC features: ATTR, SCREEN$, "
                           "POINT")

    parser.add_option("-H", "--heap-size", type="int", dest="heap_size", default=OPTIONS.heap_size.value,
                      help="Sets heap size in bytes (default %i bytes)" % OPTIONS.heap_size.value)

    parser.add_option("--debug-memory", action="store_true", dest="debug_memory", default=False,
                      help="Enables out-of-memory debug")

    parser.add_option("--debug-array", action="store_true", dest="debug_array", default=False,
                      help="Enables array boundary checking")

    parser.add_option("--strict-bool", action="store_true", dest="strict_bool", default=False,
                      help="Enforce boolean values to be 0 or 1")

    parser.add_option("--enable-break", action="store_true", dest="enable_break", default=False,
                      help="Enables program execution BREAK detection")

    parser.add_option("-E", "--emmit-backend", action="store_true", dest="emmit_backend", default=False,
                      help="Emmits backend code instead of ASM or binary")

    parser.add_option("--explicit", action="store_true", dest="explicit", default=False,
                      help="Requires all variables and functions to be declared before used")

    parser.add_option("-D", "--define", type="str", dest="defines", action="append",
                      help="Defines de given macro. Eg. -D MYDEBUG or -D NAME=Value")

    parser.add_option("-M", "--mmap", type="string", dest="memory_map", default=None,
                      help="Generate label memory map")

    parser.add_option("-i", "--ignore-case", action="store_true", dest="ignore_case", default=False,
                      help="Ignore case. Variable names are case insensitive")

    (options, args) = parser.parse_args()

    if len(args) != 1:
        parser.error("missing input file. (Try -h)")
        return 3

    # ------------------------------------------------------------
    # Setting of internal parameters according to command line
    # ------------------------------------------------------------

    OPTIONS.Debug.value = options.debug
    OPTIONS.optimization.value = options.optimization_level
    OPTIONS.outputFileName.value = options.output_file
    OPTIONS.StdErrFileName.value = options.stderr
    OPTIONS.array_base.value = options.array_base
    OPTIONS.string_base.value = options.string_base
    OPTIONS.Sinclair.value = options.sinclair
    OPTIONS.org.value = options.org
    OPTIONS.heap_size.value = options.heap_size
    OPTIONS.memoryCheck.value = options.debug_memory
    OPTIONS.strictBool.value = options.strict_bool or OPTIONS.Sinclair.value
    OPTIONS.arrayCheck.value = options.debug_array
    OPTIONS.emmitBackend.value = options.emmit_backend
    OPTIONS.enableBreak.value = options.enable_break
    OPTIONS.explicit.value = options.explicit
    OPTIONS.memory_map.value = options.memory_map

    if options.defines:
        for i in options.defines:
            name, val = tuple(i.split('=', 1))
            OPTIONS.__DEFINES.value[name] = val
            zxbpp.ID_TABLE.define(name, lineno=0)

    if OPTIONS.Sinclair.value:
        OPTIONS.array_base.value = 1
        OPTIONS.string_base.value = 1
        OPTIONS.strictBool.value = True
        OPTIONS.case_insensitive.value = True

    if options.ignore_case:
        OPTIONS.case_insensitive.value = True

    debug.ENABLED = OPTIONS.Debug.value

    if int(options.tzx) + int(options.tap) + int(options.asm) + int(options.emmit_backend) > 1:
        parser.error("Options --tap, --tzx, --emmit-backend and --asm are mutually exclusive")
        return 3

    if options.basic and not options.tzx and not options.tap:
        parser.error('Option --BASIC and --autorun requires --tzx or tap format')
        return 4

    OPTIONS.use_loader.value = options.basic
    OPTIONS.autorun.value = options.autorun

    if options.tzx:
        OPTIONS.output_file_type.value = 'tzx'
    elif options.tap:
        OPTIONS.output_file_type.value = 'tap'
    elif options.asm:
        OPTIONS.output_file_type.value = 'asm'
    elif options.emmit_backend:
        OPTIONS.output_file_type.value = 'ic'

    if not os.path.exists(args[0]):
        parser.error("No such file or directory: '%s'" % args[0])
        return 2

    if OPTIONS.memoryCheck.value:
        OPTIONS.__DEFINES.value['__MEMORY_CHECK__'] = ''
        zxbpp.ID_TABLE.define('__MEMORY_CHECK__', lineno=0)

    if OPTIONS.arrayCheck.value:
        OPTIONS.__DEFINES.value['__CHECK_ARRAY_BOUNDARY__'] = ''
        zxbpp.ID_TABLE.define('__CHECK_ARRAY_BOUNDARY__', lineno=0)

    zxbpp.main(args)
    input_ = zxbpp.OUTPUT
    OPTIONS.inputFileName.value = zxbparser.FILENAME = \
        os.path.basename(args[0])

    if not OPTIONS.outputFileName.value:
        OPTIONS.outputFileName.value = \
            os.path.splitext(os.path.basename(OPTIONS.inputFileName.value))[0] + os.path.extsep + \
            OPTIONS.output_file_type.value

    if OPTIONS.StdErrFileName.value:
        OPTIONS.stderr.value = open(OPTIONS.StdErrFileName.value, 'wt')

    zxbparser.parser.parse(input_, lexer=zxblex.lexer, tracking=True,
                           debug=(OPTIONS.Debug.value > 2))

    if gl.has_errors:
        debug.__DEBUG__("exiting due to errors.")
        return 1  # Exit with errors

    # Optimizations
    optimizer = api.optimize.OptimizerVisitor()
    optimizer.visit(zxbparser.ast)

    # Emits intermediate code
    translator = arch.zx48k.Translator()
    translator.visit(zxbparser.ast)

    # This will fill MEMORY with pending functions
    func_visitor = arch.zx48k.FunctionTranslator(gl.FUNCTIONS)
    func_visitor.start()

    # Emits default constant strings
    translator.emit_strings()

    if OPTIONS.emmitBackend.value:
        with open(OPTIONS.outputFileName.value, 'wt') as output_file:
            for quad in translator.dumpMemory(backend.MEMORY):
                output_file.write(str(quad) + '\n')

            backend.MEMORY[:] = []  # Empties memory
            # This will fill MEMORY with global declared variables
            translator = arch.zx48k.VarTranslator()
            translator.visit(zxbparser.data_ast)

            for quad in translator.dumpMemory(backend.MEMORY):
                output_file.write(str(quad) + '\n')
        return 0

    # Join all lines into a single string and ensures an INTRO at end of file
    asm_output = backend.emmit(backend.MEMORY)
    asm_output = optimize(asm_output) + '\n'

    asm_output = asm_output.split('\n')
    for i in range(len(asm_output)):
        tmp = ASMS.get(asm_output[i], None)
        if tmp is not None:
            asm_output[i] = '\n'.join(tmp)

    asm_output = '\n'.join(asm_output)

    # Now filter them against the preprocessor again
    zxbpp.setMode('asm')
    zxbpp.OUTPUT = ''
    zxbpp.filter(asm_output, args[0])

    # Now output the result
    asm_output = zxbpp.OUTPUT.split('\n')
    get_inits(asm_output)  # Find out remaining inits
    backend.MEMORY[:] = []

    # This will fill MEMORY with global declared variables
    translator = arch.zx48k.VarTranslator()
    translator.visit(zxbparser.data_ast)
    if gl.has_errors:
        debug.__DEBUG__("exiting due to errors.")
        return 1  # Exit with errors

    tmp = [x for x in backend.emmit(backend.MEMORY) if x.strip()[0] != '#']
    asm_output += tmp
    asm_output = backend.emmit_start() + asm_output
    asm_output += backend.emmit_end(asm_output)

    if options.asm:  # Only output assembler file
        with open(OPTIONS.outputFileName.value, 'wt') as output_file:
            output(asm_output, output_file)
    else:
        fout = StringIO()
        output(asm_output, fout)
        asmparse.assemble(fout.getvalue())
        fout.close()
        asmparse.generate_binary(OPTIONS.outputFileName.value, OPTIONS.output_file_type.value)

    if OPTIONS.memory_map.value:
        with open(OPTIONS.memory_map.value, 'wt') as f:
            f.write(asmparse.MEMORY.memory_map)

    sys.exit(0)  # Exit success


if __name__ == '__main__':
    main()  # Exit
