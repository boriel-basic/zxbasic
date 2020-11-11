#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et:

import sys
import os
import re
import argparse

from io import StringIO

import src.api.debug
import src.api.config
import src.api.optimize
from src.api.utils import open_file

from .version import VERSION

from . import zxbparser, zxblex
from src.libzxbpp import zxbpp
from src.libzxbasm import asmparse

from src.api.config import OPTIONS
from src.api import debug, global_ as gl

from src import arch


def get_inits(memory):
    arch.target.backend.INITS.union(zxbparser.INITS)

    reinit = re.compile(r'^#[ \t]*init[ \t]+([_a-zA-Z][_a-zA-Z0-9]*)[ \t]*$',
                        re.IGNORECASE)

    i = 0
    for m in memory:
        init = reinit.match(m)
        if init is not None:
            arch.target.backend.INITS.add(init.groups()[0])
            memory[i] = ''
        i += 1


def output(memory, ofile=None):
    """ Filters the output removing useless preprocessor #directives
    and writes it to the given file or to the screen if no file is passed
    """
    for m in memory:
        m = m.rstrip('\r\n\t ')  # Ensures no trailing newlines (might with upon includes)
        if m and m[0] == '#':  # Preprocessor directive?
            if ofile is None:
                print(m)
            else:
                ofile.write('%s\n' % m)
            continue

        # Prints a 4 spaces "tab" for non labels
        if m and ':' not in m:
            if ofile is None:
                print('    '),
            else:
                ofile.write('\t')

        if ofile is None:
            print(m)
        else:
            ofile.write('%s\n' % m)


def main(args=None, emitter=None):
    """ Entry point when executed from command line.
    You can use zxb.py as a module with import, and this
    function won't be executed.
    """
    src.api.config.init()
    zxbpp.init()
    zxbparser.init()
    arch.target.backend.init()
    arch.target.Translator.reset()
    asmparse.init()

    # ------------------------------------------------------------
    # Command line parsing
    # ------------------------------------------------------------
    parser = argparse.ArgumentParser()
    parser.add_argument('PROGRAM', type=str,
                        help='BASIC program file')
    parser.add_argument('-d', '--debug', dest='debug', default=OPTIONS.Debug, action='count',
                        help='Enable verbosity/debugging output. Additional -d increase verbosity/debug level')
    parser.add_argument('-O', '--optimize', type=int, default=OPTIONS.optimization,
                        help='Sets optimization level. '
                             '0 = None (default level is {0})'.format(OPTIONS.optimization))
    parser.add_argument('-o', '--output', type=str, dest='output_file', default=None,
                        help='Sets output file. Default is input filename with .bin extension')
    parser.add_argument('-T', '--tzx', action='store_true',
                        help="Sets output format to tzx (default is .bin)")
    parser.add_argument('-t', '--tap', action='store_true',
                        help="Sets output format to tap (default is .bin)")
    parser.add_argument('-B', '--BASIC', action='store_true', dest='basic',
                        help="Creates a BASIC loader which loads the rest of the CODE. Requires -T ot -t")
    parser.add_argument('-a', '--autorun', action='store_true',
                        help="Sets the program to be run once loaded")
    parser.add_argument('-A', '--asm', action='store_true',
                        help="Sets output format to asm")
    parser.add_argument('-S', '--org', type=str, default=str(OPTIONS.org),
                        help="Start of machine code. By default %i" % OPTIONS.org)
    parser.add_argument('-e', '--errmsg', type=str, dest='stderr', default=OPTIONS.StdErrFileName,
                        help='Error messages file (standard error console by default)')
    parser.add_argument('--array-base', type=int, default=OPTIONS.array_base,
                        help='Default lower index for arrays ({0} by default)'.format(OPTIONS.array_base))
    parser.add_argument('--string-base', type=int, default=OPTIONS.string_base,
                        help='Default lower index for strings ({0} by default)'.format(OPTIONS.array_base))
    parser.add_argument('-Z', '--sinclair', action='store_true',
                        help='Enable by default some more original ZX Spectrum Sinclair BASIC features: ATTR, SCREEN$, '
                             'POINT')
    parser.add_argument('-H', '--heap-size', type=int, default=OPTIONS.heap_size,
                        help='Sets heap size in bytes (default {0} bytes)'.format(OPTIONS.heap_size))
    parser.add_argument('--debug-memory', action='store_true',
                        help='Enables out-of-memory debug')
    parser.add_argument('--debug-array', action='store_true',
                        help='Enables array boundary checking')
    parser.add_argument('--strict-bool', action='store_true',
                        help='Enforce boolean values to be 0 or 1')
    parser.add_argument('--enable-break', action='store_true',
                        help='Enables program execution BREAK detection')
    parser.add_argument('-E', '--emit-backend', action='store_true',
                        help='Emits backend code instead of ASM or binary')
    parser.add_argument('--explicit', action='store_true',
                        help='Requires all variables and functions to be declared before used')
    parser.add_argument('-D', '--define', type=str, dest='defines', action='append',
                        help='Defines de given macro. Eg. -D MYDEBUG or -D NAME=Value')
    parser.add_argument('-M', '--mmap', type=str, dest='memory_map', default=None,
                        help='Generate label memory map')
    parser.add_argument('-i', '--ignore-case', action='store_true',
                        help='Ignore case. Makes variable names are case insensitive')
    parser.add_argument('-I', '--include-path', type=str, default='',
                        help='Add colon separated list of directories to add to include path. e.g. -I dir1:dir2')
    parser.add_argument('--strict', action='store_true',
                        help='Enables strict mode. Force explicit type declaration')
    parser.add_argument('--headerless', action='store_true',
                        help='Header-less mode: omit asm prologue and epilogue')
    parser.add_argument('--version', action='version', version='%(prog)s {0}'.format(VERSION))
    parser.add_argument('--parse-only', action='store_true',
                        help='Only parses to check for syntax and semantic errors')
    parser.add_argument('--append-binary', default=[], action='append',
                        help='Appends binary to tape file (only works with -t or -T)')
    parser.add_argument('--append-headless-binary', default=[], action='append',
                        help='Appends binary to tape file (only works with -t or -T)')
    parser.add_argument('-N', '--zxnext', action='store_true',
                        help='Enables ZX Next asm extended opcodes')
    parser.add_argument('--arch', type=str, default=arch.AVAILABLE_ARCHITECTURES[0],
                        help=f"Target architecture (defaults is'{arch.AVAILABLE_ARCHITECTURES[0]}'). "
                             f"Available architectures: {','.join(arch.AVAILABLE_ARCHITECTURES)}")

    options = parser.parse_args(args=args)

    # ------------------------------------------------------------
    # Setting of internal parameters according to command line
    # ------------------------------------------------------------

    OPTIONS.Debug = options.debug
    OPTIONS.optimization = options.optimize
    OPTIONS.outputFileName = options.output_file
    OPTIONS.StdErrFileName = options.stderr
    OPTIONS.array_base = options.array_base
    OPTIONS.string_base = options.string_base
    OPTIONS.Sinclair = options.sinclair
    OPTIONS.heap_size = options.heap_size
    OPTIONS.memoryCheck = options.debug_memory
    OPTIONS.strictBool = options.strict_bool or OPTIONS.Sinclair
    OPTIONS.arrayCheck = options.debug_array
    OPTIONS.emitBackend = options.emit_backend
    OPTIONS.enableBreak = options.enable_break
    OPTIONS.explicit = options.explicit
    OPTIONS.memory_map = options.memory_map
    OPTIONS.strict = options.strict
    OPTIONS.headerless = options.headerless
    OPTIONS.zxnext = options.zxnext

    if options.arch not in arch.AVAILABLE_ARCHITECTURES:
        parser.error(f"Invalid architecture '{options.arch}'")
        return 2
    OPTIONS.architecture = options.arch
    arch.set_target_arch(options.arch)
    backend = arch.target.backend

    OPTIONS.org = src.api.utils.parse_int(options.org)
    if OPTIONS.org is None:
        parser.error("Invalid --org option '{}'".format(options.org))

    if options.defines:
        for i in options.defines:
            macro = list(i.split('=', 1))
            name = macro[0]
            val = ''.join(macro[1:])
            OPTIONS.__DEFINES[name] = val
            zxbpp.ID_TABLE.define(name, value=val, lineno=0)

    if OPTIONS.Sinclair:
        OPTIONS.array_base = 1
        OPTIONS.string_base = 1
        OPTIONS.strictBool = True
        OPTIONS.case_insensitive = True

    if options.ignore_case:
        OPTIONS.case_insensitive = True

    debug.ENABLED = OPTIONS.Debug

    if int(options.tzx) + int(options.tap) + int(options.asm) + int(options.emit_backend) + \
            int(options.parse_only) > 1:
        parser.error("Options --tap, --tzx, --emit-backend, --parse-only and --asm are mutually exclusive")
        return 3

    if options.basic and not options.tzx and not options.tap:
        parser.error('Option --BASIC and --autorun requires --tzx or tap format')
        return 4

    if options.append_binary and not options.tzx and not options.tap:
        parser.error('Option --append-binary needs either --tap or --tzx')
        return 5

    if options.asm and options.memory_map:
        parser.error('Option --asm and --mmap cannot be used together')
        return 6

    OPTIONS.use_loader = options.basic
    OPTIONS.autorun = options.autorun

    if options.tzx:
        OPTIONS.output_file_type = 'tzx'
    elif options.tap:
        OPTIONS.output_file_type = 'tap'
    elif options.asm:
        OPTIONS.output_file_type = 'asm'
    elif options.emit_backend:
        OPTIONS.output_file_type = 'ic'

    args = [options.PROGRAM]
    if not os.path.exists(options.PROGRAM):
        parser.error("No such file or directory: '%s'" % args[0])
        return 2

    if OPTIONS.memoryCheck:
        OPTIONS.__DEFINES['__MEMORY_CHECK__'] = ''
        zxbpp.ID_TABLE.define('__MEMORY_CHECK__', lineno=0)

    if OPTIONS.arrayCheck:
        OPTIONS.__DEFINES['__CHECK_ARRAY_BOUNDARY__'] = ''
        zxbpp.ID_TABLE.define('__CHECK_ARRAY_BOUNDARY__', lineno=0)

    if OPTIONS.enableBreak:
        OPTIONS.__DEFINES['__ENABLE_BREAK__'] = ''
        zxbpp.ID_TABLE.define('__ENABLE_BREAK__', lineno=0)

    OPTIONS.include_path = options.include_path
    OPTIONS.inputFileName = zxbparser.FILENAME = \
        os.path.basename(args[0])

    if not OPTIONS.outputFileName:
        OPTIONS.outputFileName = \
            os.path.splitext(os.path.basename(OPTIONS.inputFileName))[0] + os.path.extsep + \
            OPTIONS.output_file_type

    if OPTIONS.StdErrFileName:
        OPTIONS.stderr = open_file(OPTIONS.StdErrFileName, 'wt', 'utf-8')

    zxbpp.setMode('basic')
    zxbpp.main(args)

    if gl.has_errors:
        debug.__DEBUG__("exiting due to errors.")
        return 1  # Exit with errors

    input_ = zxbpp.OUTPUT
    zxbparser.parser.parse(input_, lexer=zxblex.lexer, tracking=True,
                           debug=(OPTIONS.Debug > 1))
    if gl.has_errors:
        debug.__DEBUG__("exiting due to errors.")
        return 1  # Exit with errors

    # Optimizations
    optimizer = src.api.optimize.OptimizerVisitor()
    optimizer.visit(zxbparser.ast)

    # Emits intermediate code
    translator = arch.target.Translator()
    translator.visit(zxbparser.ast)

    if gl.DATA_IS_USED:
        gl.FUNCTIONS.extend(gl.DATA_FUNCTIONS)

    # This will fill MEMORY with pending functions
    func_visitor = arch.target.FunctionTranslator(gl.FUNCTIONS)
    func_visitor.start()

    # Emits data lines
    translator.emit_data_blocks()
    # Emits default constant strings
    translator.emit_strings()
    # Emits jump tables
    translator.emit_jump_tables()

    if OPTIONS.emitBackend:
        with open_file(OPTIONS.outputFileName, 'wt', 'utf-8') as output_file:
            for quad in translator.dumpMemory(backend.MEMORY):
                output_file.write(str(quad) + '\n')

            backend.MEMORY[:] = []  # Empties memory
            # This will fill MEMORY with global declared variables
            translator = arch.target.VarTranslator()
            translator.visit(zxbparser.data_ast)

            for quad in translator.dumpMemory(backend.MEMORY):
                output_file.write(str(quad) + '\n')
        return 0  # Exit success

    # Join all lines into a single string and ensures an INTRO at end of file
    asm_output = backend.emit(backend.MEMORY, optimize=OPTIONS.optimization > 0)
    asm_output = arch.target.optimizer.optimize(asm_output) + '\n'  # invoke the -O3

    asm_output = asm_output.split('\n')
    for i in range(len(asm_output)):
        tmp = backend.ASMS.get(asm_output[i], None)
        if tmp is not None:
            asm_output[i] = '\n'.join(tmp)

    asm_output = '\n'.join(asm_output)

    # Now filter them against the preprocessor again
    zxbpp.setMode('asm')
    zxbpp.OUTPUT = ''
    zxbpp.filter_(asm_output, args[0])

    # Now output the result
    asm_output = zxbpp.OUTPUT.split('\n')
    get_inits(asm_output)  # Find out remaining inits
    backend.MEMORY[:] = []

    # This will fill MEMORY with global declared variables
    var_checker = src.api.optimize.VariableVisitor()
    var_checker.visit(zxbparser.data_ast)
    translator = arch.target.VarTranslator()
    translator.visit(zxbparser.data_ast)
    if gl.has_errors:
        debug.__DEBUG__("exiting due to errors.")
        return 1  # Exit with errors

    tmp = [x for x in backend.emit(backend.MEMORY, optimize=False) if x.strip()[0] != '#']
    asm_output = backend.emit_start() + tmp \
                                      + ['%s:' % backend.DATA_END_LABEL, '%s:' % backend.MAIN_LABEL] \
                                      + asm_output + backend.emit_end()

    if options.asm:  # Only output assembler file
        with open_file(OPTIONS.outputFileName, 'wt', 'utf-8') as output_file:
            output(asm_output, output_file)
    elif not options.parse_only:
        fout = StringIO()
        output(asm_output, fout)
        asmparse.assemble(fout.getvalue())
        fout.close()
        asmparse.generate_binary(OPTIONS.outputFileName, OPTIONS.output_file_type,
                                 binary_files=options.append_binary,
                                 headless_binary_files=options.append_headless_binary,
                                 emitter=emitter)
        if gl.has_errors:
            return 5  # Error in assembly

    if OPTIONS.memory_map:
        if asmparse.MEMORY is not None:
            with open_file(OPTIONS.memory_map, 'wt', 'utf-8') as f:
                f.write(asmparse.MEMORY.memory_map)

    return gl.has_errors  # Exit success


if __name__ == '__main__':
    sys.exit(main())  # Exit
