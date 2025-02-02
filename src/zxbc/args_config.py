from __future__ import annotations

import os
from typing import TYPE_CHECKING

import src.api.config
import src.api.global_ as gl
from src import arch
from src.api import errmsg
from src.api.config import OPTIONS
from src.api.errmsg import warning_command_line_flag_deprecation
from src.api.utils import open_file
from src.zxbc import args_parser
from src.zxbc.args_parser import FileType

if TYPE_CHECKING:
    from argparse import Namespace

__all__ = "parse_options", "set_option_defines"


def parse_options(args: list[str] | None = None) -> Namespace:
    """Parses command line options and setup global Options container"""
    parser = args_parser.parser()
    options = parser.parse_args(args=args)

    if os.path.isfile(options.config_file):
        if src.api.config.load_config_from_file(options.config_file, src.api.config.ConfigSections.ZXBC):
            src.api.errmsg.info(f"Config file {options.config_file} loaded")

    # ------------------------------------------------------------
    # Setting of internal parameters according to command line
    # ------------------------------------------------------------
    OPTIONS.debug_level = options.debug
    OPTIONS.optimization_level = options.optimize
    OPTIONS.output_filename = options.output_file
    OPTIONS.stderr_filename = options.stderr
    OPTIONS.array_base = options.array_base
    OPTIONS.string_base = options.string_base
    OPTIONS.sinclair = options.sinclair
    OPTIONS.heap_size = options.heap_size
    OPTIONS.memory_check = options.debug_memory
    OPTIONS.strict_bool = options.strict_bool
    OPTIONS.array_check = options.debug_array
    OPTIONS.enable_break = options.enable_break
    OPTIONS.explicit = options.explicit
    OPTIONS.memory_map = options.memory_map
    OPTIONS.strict = options.strict
    OPTIONS.headerless = options.headerless
    OPTIONS.zxnext = options.zxnext
    OPTIONS.expected_warnings = gl.EXPECTED_WARNINGS = options.expect_warnings
    OPTIONS.hide_warning_codes = options.hide_warning_codes
    OPTIONS.opt_strategy = options.opt_strategy

    if options.arch not in arch.AVAILABLE_ARCHITECTURES:
        parser.error(f"Invalid architecture '{options.arch}'")

    OPTIONS.architecture = options.arch

    # region [Enable/Disable Warnings]
    enabled_warnings = set(options.enable_warning or [])
    disabled_warnings = set(options.disable_warning or [])
    duplicated_options = [f"W{x}" for x in enabled_warnings.intersection(disabled_warnings)]

    if duplicated_options:
        parser.error(f"Warning(s) {', '.join(duplicated_options)} cannot be enabled and disabled simultaneously")

    for warn_code in enabled_warnings:
        errmsg.enable_warning(warn_code)

    for warn_code in disabled_warnings:
        errmsg.disable_warning(warn_code)

    # endregion

    OPTIONS.org = OPTIONS.org if options.org is None else src.api.utils.parse_int(options.org)
    if OPTIONS.org is None:
        parser.error(f"Invalid --org option '{options.org}'")

    OPTIONS.heap_address = (
        OPTIONS.heap_address if options.heap_address is None else src.api.utils.parse_int(options.heap_address)
    )

    if options.defines:
        for i in options.defines:
            macro = list(i.split("=", 1))
            name = macro[0]
            val = "".join(macro[1:])
            OPTIONS.__DEFINES[name] = val

    if OPTIONS.sinclair:
        OPTIONS.array_base = 1
        OPTIONS.string_base = 1
        OPTIONS.case_insensitive = True

    OPTIONS.case_insensitive = options.ignore_case
    OPTIONS.use_basic_loader = options.basic
    OPTIONS.autorun = options.autorun

    if options.output_format:
        OPTIONS.output_file_type = options.output_format
    elif options.tzx:
        OPTIONS.output_file_type = FileType.TZX
        warning_command_line_flag_deprecation(
            f"--tzx (use -f {FileType.TZX} or --output-format={FileType.TZX} instead)"
        )
    elif options.tap:
        OPTIONS.output_file_type = FileType.TAP
        warning_command_line_flag_deprecation(
            f"--tap (use -f {FileType.TAP} or --output-format={FileType.TAP} instead)"
        )
    elif options.asm:
        OPTIONS.output_file_type = FileType.ASM
        warning_command_line_flag_deprecation(
            f"--asm (use -f {FileType.ASM} or --output-format={FileType.ASM} instead)"
        )
    elif options.emit_backend:
        OPTIONS.output_file_type = FileType.IR
        warning_command_line_flag_deprecation(
            f"--emit-backend (use -f {FileType.IR} or --output-format={FileType.IR} instead)"
        )

    if OPTIONS.strict_bool:
        OPTIONS.strict_bool = False
        warning_command_line_flag_deprecation("--strict-bool is deprecated (no longer needed)")

    if OPTIONS.output_file_type == FileType.IR:
        OPTIONS.emit_backend = True

    if (options.basic or options.autorun) and OPTIONS.output_file_type not in {
        FileType.TAP,
        FileType.TZX,
        FileType.SNA,
        FileType.Z80,
    }:
        parser.error("Options --BASIC and --autorun require one of sna, tzx, tap or z80 output format")

    if not (options.basic and options.autorun) and OPTIONS.output_file_type in {
        FileType.SNA,
        FileType.Z80,
    }:
        parser.error("Options --BASIC and --autorun are both required for snapshot formats")

    if options.append_binary and OPTIONS.output_file_type not in {FileType.TAP, FileType.TZX}:
        parser.error("Option --append-binary needs either tap or tzx output format")

    if OPTIONS.output_file_type == FileType.ASM and options.memory_map:
        parser.error("Option --asm and --mmap cannot be used together")

    args = [options.PROGRAM]
    if not os.path.exists(options.PROGRAM):
        parser.error("No such file or directory: '%s'" % args[0])

    set_option_defines()

    OPTIONS.include_path = options.include_path
    OPTIONS.input_filename = os.path.basename(args[0])

    if not OPTIONS.output_filename:
        OPTIONS.output_filename = (
            os.path.splitext(os.path.basename(OPTIONS.input_filename))[0] + os.path.extsep + OPTIONS.output_file_type
        )

    if OPTIONS.stderr_filename:
        OPTIONS.stderr = open_file(OPTIONS.stderr_filename, "wt", "utf-8")

    return options


def set_option_defines() -> None:
    """Sets some macros automatically, according to options"""
    if OPTIONS.memory_check:
        OPTIONS.__DEFINES["__MEMORY_CHECK__"] = ""

    if OPTIONS.array_check:
        OPTIONS.__DEFINES["__CHECK_ARRAY_BOUNDARY__"] = ""

    if OPTIONS.enable_break:
        OPTIONS.__DEFINES["__ENABLE_BREAK__"] = ""
