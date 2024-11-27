# vim:ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import configparser
import enum
import os
import sys
from collections.abc import Callable
from enum import StrEnum

from src.api import errmsg, global_, options, python_version_check
from src.api.options import ANYTYPE, Action

# The options container


# ------------------------------------------------------
# Common setup and configuration for all tools
# ------------------------------------------------------
@enum.unique
class ConfigSections(StrEnum):
    ZXBC = "zxbc"
    ZXBASM = "zxbasm"
    ZXBPP = "zxbpp"


@enum.unique
class OptimizationStrategy(StrEnum):
    Size = "size"
    Speed = "speed"
    Auto = "auto"


@enum.unique
class OPTION(StrEnum):
    OUTPUT_FILENAME = "output_filename"
    INPUT_FILENAME = "input_filename"
    STDERR_FILENAME = "stderr_filename"
    DEBUG = "debug_level"
    PROJECT_FILENAME = "project_filename"

    # File IO
    STDIN = "stdin"
    STDOUT = "stdout"
    STDERR = "stderr"

    O_LEVEL = "optimization_level"
    CASE_INS = "case_insensitive"
    ARRAY_BASE = "array_base"
    STR_BASE = "string_base"
    DEFAULT_BYREF = "default_byref"
    MAX_SYN_ERRORS = "max_syntax_errors"

    MEMORY_MAP = "memory_map"

    USE_BASIC_LOADER = "use_basic_loader"
    AUTORUN = "autorun"
    OUTPUT_FILE_TYPE = "output_file_type"
    INCLUDE_PATH = "include_path"

    CHECK_MEMORY = "memory_check"
    CHECK_ARRAYS = "array_check"

    STRICT_BOOL = "strict_bool"

    ENABLE_BREAK = "enable_break"
    EMIT_BACKEND = "emit_backend"

    EXPLICIT = "explicit"
    STRICT = "strict"

    ARCH = "architecture"
    EXPECTED_WARNINGS = "expected_warnings"
    HIDE_WARNING_CODES = "hide_warning_codes"

    # ASM Options
    ASM_ZXNEXT = "zxnext"
    FORCE_ASM_BRACKET = "force_asm_brackets"

    # Optimization Preferences
    OPT_STRATEGY = "opt_strategy"


OPTIONS = options.Options()
OPTIONS_NOT_SAVED = {
    OPTION.STDERR,
    OPTION.STDIN,
    OPTION.STDOUT,
    "sinclair",
    OPTION.INPUT_FILENAME,
    OPTION.OUTPUT_FILENAME,
    OPTION.PROJECT_FILENAME,
    "heap_start_label",
    "heap_size_label",
}


def load_config_from_file(
    filename: str, section: ConfigSections, options_: options.Options | None = None, *, stop_on_error: bool = True
) -> bool:
    """Opens file and read options from the given section. If stop_on_error is set,
    the program stop if any error is found. Otherwise, the result of the operation will be
    returned (True on success, False on failure)
    """
    assert isinstance(section, ConfigSections)
    section_ = section.value

    if options_ is None:
        options_ = OPTIONS

    try:
        cfg = configparser.ConfigParser()
        cfg.read(filename, encoding="utf-8")
    except (configparser.DuplicateSectionError, configparser.DuplicateOptionError):
        errmsg.msg_output(f"Invalid config file '{filename}': it has duplicated fields")
        if stop_on_error:
            sys.exit(1)
        return False
    except FileNotFoundError:
        errmsg.msg_output(f"Config file '{filename}' not found")
        if stop_on_error:
            sys.exit(1)
        return False

    if section_ not in cfg.sections():
        errmsg.msg_output(f"Section '{section_}' not found in config file '{filename}'")
        if stop_on_error:
            sys.exit(1)
        return False

    parsing: dict[type, Callable] = {int: cfg.getint, float: cfg.getfloat, bool: cfg.getboolean}

    for opt in cfg.options(section_):
        options_[opt].value = parsing.get(options_[opt].type, cfg.get)(section=section, option=opt)

    return True


def save_config_into_file(
    filename: str, section: ConfigSections, options_: options.Options | None = None, *, stop_on_error: bool = True
) -> bool:
    """Save config into config ini file into the given section. If stop_on_error is set,
    the program stop. Otherwise, the result of the operation will be
    returned (True on success, False on failure)
    """
    assert isinstance(section, ConfigSections)
    section_ = section.value

    if options_ is None:
        options_ = OPTIONS

    cfg = configparser.ConfigParser()
    if os.path.exists(filename):
        try:
            cfg.read(filename, encoding="utf-8")
        except (configparser.DuplicateSectionError, configparser.DuplicateOptionError):
            errmsg.msg_output(f"Invalid config file '{filename}': it has duplicated fields")
            if stop_on_error:
                sys.exit(1)
            return False

    cfg[section_] = {}
    for opt_name, opt in options_().items():
        if opt_name.startswith("__") or opt.value is None or opt_name in OPTIONS_NOT_SAVED:
            continue

        if opt.type is bool:
            cfg[section_][opt_name] = str(opt.value).lower()
            continue

        cfg[section_][opt_name] = str(opt.value)

    try:
        with open(filename, "wt", encoding="utf-8") as f:
            cfg.write(f)
    except IOError:
        errmsg.msg_output(f"Can't write config file '{filename}'")
        if stop_on_error:
            sys.exit(1)
        return False

    return True


def init() -> None:
    """Default Options and Compilation Flags"""
    python_version_check.init()
    OPTIONS(Action.CLEAR)

    OPTIONS(Action.ADD, name=OPTION.OUTPUT_FILENAME, type=str)
    OPTIONS(Action.ADD, name=OPTION.INPUT_FILENAME, type=str)
    OPTIONS(Action.ADD, name=OPTION.STDERR_FILENAME, type=str, ignore_none=True)
    OPTIONS(Action.ADD, name=OPTION.DEBUG, type=int, default=0, ignore_none=True)

    # Default console redirections
    OPTIONS(Action.ADD, name=OPTION.STDIN, type=ANYTYPE, default=sys.stdin)
    OPTIONS(Action.ADD, name=OPTION.STDOUT, type=ANYTYPE, default=sys.stdout)
    OPTIONS(Action.ADD, name=OPTION.STDERR, type=ANYTYPE, default=sys.stderr)

    OPTIONS(Action.ADD, name=OPTION.O_LEVEL, type=int, default=global_.DEFAULT_OPTIMIZATION_LEVEL, ignore_none=True)
    OPTIONS(Action.ADD, name=OPTION.CASE_INS, type=bool, default=False, ignore_none=True)
    OPTIONS(Action.ADD, name=OPTION.ARRAY_BASE, type=int, default=0, ignore_none=True)
    OPTIONS(Action.ADD, name=OPTION.DEFAULT_BYREF, type=bool, default=False, ignore_none=True)
    OPTIONS(Action.ADD, name=OPTION.MAX_SYN_ERRORS, type=int, default=global_.DEFAULT_MAX_SYNTAX_ERRORS)
    OPTIONS(Action.ADD, name=OPTION.STR_BASE, type=int, default=0, ignore_none=True)
    OPTIONS(Action.ADD, name=OPTION.MEMORY_MAP, type=str, default=None, ignore_none=True)
    OPTIONS(Action.ADD, name=OPTION.FORCE_ASM_BRACKET, type=bool, default=False, ignore_none=True)

    OPTIONS(Action.ADD, name=OPTION.USE_BASIC_LOADER, type=bool, default=False, ignore_none=True)

    # Whether to add autostart code (needs basic loader = true)
    OPTIONS(Action.ADD, name=OPTION.AUTORUN, type=bool, default=False, ignore_none=True)
    OPTIONS(Action.ADD, name=OPTION.OUTPUT_FILE_TYPE, type=str, default="bin")  # bin, tap, tzx etc...
    OPTIONS(Action.ADD, name=OPTION.INCLUDE_PATH, type=str, default="")  # Include path, like '/var/lib:/var/include'

    OPTIONS(Action.ADD, name=OPTION.CHECK_MEMORY, type=bool, default=False, ignore_none=True)
    OPTIONS(Action.ADD, name=OPTION.STRICT_BOOL, type=bool, default=False, ignore_none=True)
    OPTIONS(Action.ADD, name=OPTION.CHECK_ARRAYS, type=bool, default=False, ignore_none=True)

    OPTIONS(Action.ADD, name=OPTION.ENABLE_BREAK, type=bool, default=False, ignore_none=True)
    OPTIONS(Action.ADD, name=OPTION.EMIT_BACKEND, type=bool, default=False)
    OPTIONS(Action.ADD, name="__DEFINES", type=dict, default={})
    OPTIONS(Action.ADD, name=OPTION.EXPLICIT, type=bool, default=False, ignore_none=True)
    OPTIONS(Action.ADD, name="sinclair", type=bool, default=False)
    OPTIONS(Action.ADD, name=OPTION.STRICT, type=bool, default=False, ignore_none=True)  # True to force type checking
    OPTIONS(Action.ADD, name=OPTION.ASM_ZXNEXT, type=bool, default=False, ignore_none=True)  # Enable ZX Next ASM
    OPTIONS(Action.ADD, name=OPTION.ARCH, type=str, default=None, ignore_none=True)  # Architecture
    OPTIONS(Action.ADD, name=OPTION.EXPECTED_WARNINGS, type=int, default=0, ignore_none=True)

    # Whether to show WXXX warning codes or not
    OPTIONS(Action.ADD, name=OPTION.HIDE_WARNING_CODES, type=bool, default=False, ignore_none=True)

    # Optimization preferences
    OPTIONS(
        Action.ADD,
        name=OPTION.OPT_STRATEGY,
        type=OptimizationStrategy,
        default=OptimizationStrategy.Auto,
        ignore_none=True,
    )

    OPTIONS(
        Action.ADD,
        name=OPTION.PROJECT_FILENAME,
        type=str,
        default=os.path.join(os.path.abspath(os.path.curdir), "project.ini"),
    )


init()
