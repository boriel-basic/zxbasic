#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import os
import sys
import configparser

from src import api

# The options container
from . import options
from . import global_
from .options import ANYTYPE


# ------------------------------------------------------
# Common setup and configuration for all tools
# ------------------------------------------------------
class OPTION:
    OUTPUT_FILENAME = 'output_filename'
    INPUT_FILENAME = 'input_filename'
    STDERR_FILENAME = 'stderr_filename'
    DEBUG = 'debug_level'

    # File IO
    STDIN = 'stdin'
    STDOUT = 'stdout'
    STDERR = 'stderr'

    O_LEVEL = 'optimization_level'
    CASE_INS = 'case_insensitive'
    ARRAY_BASE = 'array_base'
    STR_BASE = 'string_base'
    DEFAULT_BYREF = 'default_byref'
    MAX_SYN_ERRORS = 'max_syntax_errors'

    MEMORY_MAP = 'memory_map'

    USE_BASIC_LOADER = 'use_basic_loader'
    AUTORUN = 'autorun'
    OUTPUT_FILE_TYPE = 'output_file_type'
    INCLUDE_PATH = 'include_path'

    CHECK_MEMORY = 'memory_check'
    CHECK_ARRAYS = 'array_check'

    STRICT_BOOL = 'strict_bool'

    ENABLE_BREAK = 'enable_break'
    EMIT_BACKEND = 'emit_backend'

    EXPLICIT = 'explicit'
    STRICT = 'strict'

    ARCH = 'architecture'
    EXPECTED_WARNINGS = 'expected_warnings'
    HIDE_WARNING_CODES = 'hide_warning_codes'

    # ASM Options
    ASM_ZXNEXT = 'zxnext'
    FORCE_ASM_BRACKET = 'force_asm_brackets'


OPTIONS = options.Options()


def load_config_from_file(filename: str, section: str, options_: options.Options = None, stop_on_error=True) -> bool:
    """ Opens file and read options from the given section. If stop_on_error is set,
    the program stop. Otherwise the result of the operation will be
    returned (True on success, False on failure)
    """
    if options_ is None:
        options_ = OPTIONS

    try:
        cfg = configparser.ConfigParser()
        cfg.read(filename, encoding='utf-8')
    except (configparser.DuplicateSectionError, configparser.DuplicateOptionError):
        api.errmsg.msg_output(f"Invalid config file '{filename}': it has duplicated fields")
        if stop_on_error:
            sys.exit(1)
        return False
    except FileNotFoundError:
        api.errmsg.msg_output(f"Config file '{filename}' not found")
        if stop_on_error:
            sys.exit(1)
        return False

    if section not in cfg.sections():
        api.errmsg.msg_output(f"Section '{section}' not found in config file '{filename}'")
        if stop_on_error:
            sys.exit(1)
        return False

    parsing = {
        int: cfg.getint,
        float: cfg.getfloat,
        bool: cfg.getboolean
    }

    for opt in cfg.options(section):
        options_[opt].value = parsing.get(options_[opt].type, cfg.get)(option=opt)

    return True


def save_config_into_file(filename: str, section: str, options_: options.Options = None, stop_on_error=True) -> bool:
    """ Save config into config ini file into the given section. If stop_on_error is set,
    the program stop. Otherwise the result of the operation will be
    returned (True on success, False on failure)
    """
    if options_ is None:
        options_ = OPTIONS

    cfg = configparser.ConfigParser()
    if os.path.exists(filename):
        try:
            cfg.read(filename, encoding='utf-8')
        except (configparser.DuplicateSectionError, configparser.DuplicateOptionError):
            api.errmsg.msg_output(f"Invalid config file '{filename}': it has duplicated fields")
            if stop_on_error:
                sys.exit(1)
            return False

    cfg[section] = {}
    for opt_name, opt in options.Options.get_options(options_):
        if opt_name.startswith('__') or opt.value is None or opt_name in ('stderr', 'stdin', 'stdout'):
            continue

        if opt.type == bool:
            cfg[section][opt_name] = str(opt.value).lower()
            continue

        cfg[section][opt_name] = str(opt.value)

    try:
        with open(filename, 'wt', encoding='utf-8') as f:
            cfg.write(f)
    except IOError:
        api.errmsg.msg_output(f"Can't write config file '{filename}'")
        if stop_on_error:
            sys.exit(1)
        return False

    return True


def init():
    """
    Default Options and Compilation Flags

    optimization -- Optimization level. Use -O flag to change.
    case_insensitive -- Whether user identifiers are case insensitive
                             or not
    array_base -- Default array lower bound
    param_byref --Default parameter passing. TRUE => By Reference
    """

    OPTIONS.reset()

    OPTIONS.add_option(OPTION.OUTPUT_FILENAME, str)
    OPTIONS.add_option(OPTION.INPUT_FILENAME, str)
    OPTIONS.add_option(OPTION.STDERR_FILENAME, str)
    OPTIONS.add_option(OPTION.DEBUG, int, 0)

    # Default console redirections
    OPTIONS.add_option(OPTION.STDIN, ANYTYPE, sys.stdin)
    OPTIONS.add_option(OPTION.STDOUT, ANYTYPE, sys.stdout)
    OPTIONS.add_option(OPTION.STDERR, ANYTYPE, sys.stderr)

    OPTIONS.add_option(OPTION.O_LEVEL, int, global_.DEFAULT_OPTIMIZATION_LEVEL)
    OPTIONS.add_option(OPTION.CASE_INS, bool, False)
    OPTIONS.add_option(OPTION.ARRAY_BASE, int, 0)
    OPTIONS.add_option(OPTION.DEFAULT_BYREF, bool, False)
    OPTIONS.add_option(OPTION.MAX_SYN_ERRORS, int, global_.DEFAULT_MAX_SYNTAX_ERRORS)
    OPTIONS.add_option(OPTION.STR_BASE, int, 0)
    OPTIONS.add_option(OPTION.MEMORY_MAP, str, None)
    OPTIONS.add_option(OPTION.FORCE_ASM_BRACKET, bool, False)

    OPTIONS.add_option(OPTION.USE_BASIC_LOADER, bool, False)  # Whether to use a loader
    OPTIONS.add_option(OPTION.AUTORUN, bool, False)  # Whether to add autostart code (needs basic loader = true)
    OPTIONS.add_option(OPTION.OUTPUT_FILE_TYPE, str, 'bin')  # bin, tap, tzx etc...
    OPTIONS.add_option(OPTION.INCLUDE_PATH, str, '')  # Include path, like '/var/lib:/var/include'

    OPTIONS.add_option(OPTION.CHECK_MEMORY, bool, False)
    OPTIONS.add_option(OPTION.STRICT_BOOL, bool, False)
    OPTIONS.add_option(OPTION.CHECK_ARRAYS, bool, False)

    OPTIONS.add_option(OPTION.ENABLE_BREAK, bool, False)
    OPTIONS.add_option(OPTION.EMIT_BACKEND, bool, False)
    OPTIONS.add_option('__DEFINES', dict, {})
    OPTIONS.add_option(OPTION.EXPLICIT, bool, False)
    OPTIONS.add_option('Sinclair', bool, False)
    OPTIONS.add_option(OPTION.STRICT, bool, False)  # True to force type checking
    OPTIONS.add_option(OPTION.ASM_ZXNEXT, bool, False)  # True to enable ZX Next ASM opcodes
    OPTIONS.add_option(OPTION.ARCH, str, None)  # Architecture
    OPTIONS.add_option(OPTION.EXPECTED_WARNINGS, int, 0)  # Expected Warnings that will be silenced
    OPTIONS.add_option(OPTION.HIDE_WARNING_CODES, bool, False)  # Whether to show WXXX warning codes or not

    save_config_into_file('project.ini', 'zxbc', stop_on_error=True)


init()
