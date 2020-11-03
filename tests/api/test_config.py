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
        self.assertEqual(config.OPTIONS.Debug, 0)
        self.assertEqual(config.OPTIONS.stdin, sys.stdin)
        self.assertEqual(config.OPTIONS.stdout, sys.stdout)
        self.assertEqual(config.OPTIONS.stderr, sys.stderr)
        self.assertEqual(config.OPTIONS.optimization, global_.DEFAULT_OPTIMIZATION_LEVEL)
        self.assertEqual(config.OPTIONS.case_insensitive, False)
        self.assertEqual(config.OPTIONS.array_base, 0)
        self.assertEqual(config.OPTIONS.byref, False)
        self.assertEqual(config.OPTIONS.max_syntax_errors, global_.DEFAULT_MAX_SYNTAX_ERRORS)
        self.assertEqual(config.OPTIONS.string_base, 0)
        self.assertIsNone(config.OPTIONS.memory_map)
        self.assertEqual(config.OPTIONS.bracket, False)
        self.assertEqual(config.OPTIONS.use_loader, False)
        self.assertEqual(config.OPTIONS.autorun, False)
        self.assertEqual(config.OPTIONS.output_file_type, 'bin')
        self.assertEqual(config.OPTIONS.include_path, '')
        self.assertEqual(config.OPTIONS.memoryCheck, False)
        self.assertEqual(config.OPTIONS.strictBool, False)
        self.assertEqual(config.OPTIONS.arrayCheck, False)
        self.assertEqual(config.OPTIONS.enableBreak, False)
        self.assertEqual(config.OPTIONS.emitBackend, False)
        self.assertIsNone(config.OPTIONS.architecture)
        # private options that cannot be accessed with #pragma
        self.assertEqual(config.OPTIONS['__DEFINES'].value, {})
        self.assertEqual(config.OPTIONS.explicit, False)
        self.assertEqual(config.OPTIONS.Sinclair, False)
        self.assertEqual(config.OPTIONS.strict, False)

    def test_initted_values(self):
        config.init()
        self.assertEqual(sorted(config.OPTIONS._options.keys()), [
            'Debug',
            'Sinclair',
            'StdErrFileName',
            '__DEFINES',
            'architecture',
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
            'zxnext'
        ])
