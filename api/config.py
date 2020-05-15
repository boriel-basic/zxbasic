#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import sys

# The options container
from . import options
from . import global_
from .options import ANYTYPE

# ------------------------------------------------------
# Common setup and configuration for all tools
# ------------------------------------------------------

OPTIONS = options.Options()


def init():
    OPTIONS.reset()
    OPTIONS.add_option('outputFileName', str)
    OPTIONS.add_option('inputFileName', str)
    OPTIONS.add_option('StdErrFileName', str)
    OPTIONS.add_option('Debug', int, 0)

    # Default console redirections
    OPTIONS.add_option('stdin', ANYTYPE, sys.stdin)
    OPTIONS.add_option('stdout', ANYTYPE, sys.stdout)
    OPTIONS.add_option('stderr', ANYTYPE, sys.stderr)

    # ----------------------------------------------------------------------
    # Default Options and Compilation Flags
    #
    # optimization -- Optimization level. Use -O flag to change.
    # case_insensitive -- Whether user identifiers are case insensitive
    #                          or not
    # array_base -- Default array lower bound
    # param_byref --Default parameter passing. TRUE => By Reference
    # ----------------------------------------------------------------------
    OPTIONS.add_option('optimization', int, global_.DEFAULT_OPTIMIZATION_LEVEL)
    OPTIONS.add_option('case_insensitive', bool, False)
    OPTIONS.add_option('array_base', int, 0)
    OPTIONS.add_option('byref', bool, False)
    OPTIONS.add_option('max_syntax_errors', int, global_.DEFAULT_MAX_SYNTAX_ERRORS)
    OPTIONS.add_option('string_base', int, 0)
    OPTIONS.add_option('memory_map', str, None)
    OPTIONS.add_option('bracket', bool, False)

    OPTIONS.add_option('use_loader', bool, False)  # Whether to use a loader
    OPTIONS.add_option('autorun', bool, False)  # Whether to add autostart code (needs basic loader = true)
    OPTIONS.add_option('output_file_type', str, 'bin')  # bin, tap, tzx etc...
    OPTIONS.add_option('include_path', str, '')  # Include path, like '/var/lib:/var/include'

    OPTIONS.add_option('memoryCheck', bool, False)
    OPTIONS.add_option('strictBool', bool, False)
    OPTIONS.add_option('arrayCheck', bool, False)
    OPTIONS.add_option('enableBreak', bool, False)
    OPTIONS.add_option('emitBackend', bool, False)
    OPTIONS.add_option('arch', str, 'zx48k')
    OPTIONS.add_option('__DEFINES', dict, {})
    OPTIONS.add_option('explicit', bool, False)
    OPTIONS.add_option('Sinclair', bool, False)
    OPTIONS.add_option('strict', bool, False)  # True to force type checking
    OPTIONS.add_option('zxnext', bool, False)  # True to enable ZX Next ASM opcodes


init()
