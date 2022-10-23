#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import unittest

from src.api import config, global_


class TestConfig(unittest.TestCase):
    """Tests api.config initialization"""

    def setUp(self):
        config.OPTIONS(config.Action.CLEAR)
        config.init()

    def test_init(self):
        self.assertEqual(config.OPTIONS.debug_level, 0)
        self.assertEqual(config.OPTIONS.stdin, sys.stdin)
        self.assertEqual(config.OPTIONS.stdout, sys.stdout)
        self.assertEqual(config.OPTIONS.stderr, sys.stderr)
        self.assertEqual(config.OPTIONS.optimization_level, global_.DEFAULT_OPTIMIZATION_LEVEL)
        self.assertEqual(config.OPTIONS.case_insensitive, False)
        self.assertEqual(config.OPTIONS.array_base, 0)
        self.assertEqual(config.OPTIONS.default_byref, False)
        self.assertEqual(config.OPTIONS.max_syntax_errors, global_.DEFAULT_MAX_SYNTAX_ERRORS)
        self.assertEqual(config.OPTIONS.string_base, 0)
        self.assertIsNone(config.OPTIONS.memory_map)
        self.assertEqual(config.OPTIONS.force_asm_brackets, False)
        self.assertEqual(config.OPTIONS.use_basic_loader, False)
        self.assertEqual(config.OPTIONS.autorun, False)
        self.assertEqual(config.OPTIONS.output_file_type, "bin")
        self.assertEqual(config.OPTIONS.include_path, "")
        self.assertEqual(config.OPTIONS.memory_check, False)
        self.assertEqual(config.OPTIONS.strict_bool, False)
        self.assertEqual(config.OPTIONS.array_check, False)
        self.assertEqual(config.OPTIONS.enable_break, False)
        self.assertEqual(config.OPTIONS.emit_backend, False)
        self.assertIsNone(config.OPTIONS.architecture)
        self.assertEqual(config.OPTIONS.expected_warnings, 0)

        # private options that cannot be accessed with #pragma
        self.assertEqual(config.OPTIONS["__DEFINES"].value, {})
        self.assertEqual(config.OPTIONS.explicit, False)
        self.assertEqual(config.OPTIONS.sinclair, False)
        self.assertEqual(config.OPTIONS.strict, False)

    def test_initted_values(self):
        self.assertEqual(
            sorted(config.OPTIONS._options.keys()),
            [
                "__DEFINES",
                config.OPTION.ARCH,
                config.OPTION.ARRAY_BASE,
                config.OPTION.CHECK_ARRAYS,
                config.OPTION.AUTORUN,
                config.OPTION.CASE_INS,
                config.OPTION.DEBUG,
                config.OPTION.DEFAULT_BYREF,
                config.OPTION.EMIT_BACKEND,
                config.OPTION.ENABLE_BREAK,
                config.OPTION.EXPECTED_WARNINGS,
                config.OPTION.EXPLICIT,
                config.OPTION.FORCE_ASM_BRACKET,
                config.OPTION.HIDE_WARNING_CODES,
                config.OPTION.INCLUDE_PATH,
                config.OPTION.INPUT_FILENAME,
                config.OPTION.MAX_SYN_ERRORS,
                config.OPTION.CHECK_MEMORY,
                config.OPTION.MEMORY_MAP,
                config.OPTION.O_LEVEL,
                config.OPTION.OUTPUT_FILE_TYPE,
                config.OPTION.OUTPUT_FILENAME,
                "project_filename",
                "sinclair",
                config.OPTION.STDERR,
                config.OPTION.STDERR_FILENAME,
                config.OPTION.STDIN,
                config.OPTION.STDOUT,
                config.OPTION.STRICT,
                config.OPTION.STRICT_BOOL,
                config.OPTION.STR_BASE,
                config.OPTION.USE_BASIC_LOADER,
                config.OPTION.ASM_ZXNEXT,
            ],
        )

    def test_loader_ignore_none(self):
        """Some settings must ignore "None" assignments, since
        this means the user didn't specify anything from the command line
        """
        config.OPTIONS.use_basic_loader = True
        config.OPTIONS.use_basic_loader = None
        self.assertEqual(config.OPTIONS.use_basic_loader, True)

    def test_autorun_ignore_none(self):
        """Some settings must ignore "None" assignments, since
        this means the user didn't specify anything from the command line
        """
        config.OPTIONS.autorun = True
        config.OPTIONS.autorun = None
        self.assertEqual(config.OPTIONS.autorun, True)
