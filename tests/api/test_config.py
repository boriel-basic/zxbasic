#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
import sys
from api import config
from api import global_


class TestConfig(unittest.TestCase):
    """ Tests api.config initialization
    """
    def setUp(self):
        config.OPTIONS.reset()

    def test_init(self):
        config.init()
        self.assertEqual(config.OPTIONS.Debug.value, 0)
        self.assertEqual(config.OPTIONS.stdin.value, sys.stdin)
        self.assertEqual(config.OPTIONS.stdout.value, sys.stdout)
        self.assertEqual(config.OPTIONS.stderr.value, sys.stderr)
        self.assertEqual(config.OPTIONS.optimization.value, global_.DEFAULT_OPTIMIZATION_LEVEL)
        self.assertEqual(config.OPTIONS.case_insensitive.value, False)
        self.assertEqual(config.OPTIONS.array_base.value, 0)
        self.assertEqual(config.OPTIONS.byref.value, False)
        self.assertEqual(config.OPTIONS.max_syntax_errors.value, global_.DEFAULT_MAX_SYNTAX_ERRORS)
        self.assertEqual(config.OPTIONS.string_base.value, 0)
        self.assertEqual(config.OPTIONS.memory_map.value, None)
        self.assertEqual(config.OPTIONS.bracket.value, False)
        self.assertEqual(config.OPTIONS.use_loader.value, False)
        self.assertEqual(config.OPTIONS.autorun.value, False)
        self.assertEqual(config.OPTIONS.output_file_type.value, 'bin')
        self.assertEqual(config.OPTIONS.include_path.value, '')
        self.assertEqual(config.OPTIONS.memoryCheck.value, False)
        self.assertEqual(config.OPTIONS.strictBool.value, False)
        self.assertEqual(config.OPTIONS.arrayCheck.value, False)
        self.assertEqual(config.OPTIONS.enableBreak.value, False)
        self.assertEqual(config.OPTIONS.emitBackend.value, False)
        self.assertEqual(config.OPTIONS.arch.value, 'zx48k')
        # private options that cannot be accessed with #pragma
        self.assertEqual(config.OPTIONS.option('__DEFINES').value, {})
        self.assertEqual(config.OPTIONS.explicit.value, False)
        self.assertEqual(config.OPTIONS.Sinclair.value, False)
        self.assertEqual(config.OPTIONS.strict.value, False)

    def test_initted_values(self):
        config.init()
        self.assertEqual(sorted(config.OPTIONS.options.keys()), ['Debug',
                                                                 'Sinclair',
                                                                 'StdErrFileName',
                                                                 '__DEFINES',
                                                                 'arch',
                                                                 'arrayCheck',
                                                                 'array_base',
                                                                 'autorun',
                                                                 'bracket',
                                                                 'byref',
                                                                 'case_insensitive',
                                                                 'emitBackend',
                                                                 'enableBreak',
                                                                 'explicit',
                                                                 'include_path',
                                                                 'inputFileName',
                                                                 'max_syntax_errors',
                                                                 'memoryCheck',
                                                                 'memory_map',
                                                                 'optimization',
                                                                 'outputFileName',
                                                                 'output_file_type',
                                                                 'stderr',
                                                                 'stdin',
                                                                 'stdout',
                                                                 'strict',
                                                                 'strictBool',
                                                                 'string_base',
                                                                 'use_loader',
                                                                 'zxnext'])
