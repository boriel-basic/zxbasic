# -*- coding: utf-8 -*-

import unittest

from src.arch.zx48k.peephole import parser


class TestParser(unittest.TestCase):
    maxDiff = None

    def test_parse_string(self):
        result = parser.parse_str('''
        OLEVEL: 1
        ;; Comment
        
        OFLAG: 15
        
        REPLACE {{
         push $1
         pop $1
        }}    
        
        IF {{
          $1 == "af'" && $1 == "Hello ""World""" &&
          ($1 == "(hl)" || IS_INDIR($1)) || $1 == "aa"
        }}
        
        WITH {{
        }}
        ''')  # noqa

        self.maxDiff = None
        self.assertIsInstance(result, dict)
        self.assertDictEqual(result, {
            'DEFINE': [],
            'IF': [
                [
                    [
                        ['$1', '==', "af'"],
                        '&&',
                        ['$1', '==', 'Hello ""World""']
                    ],
                    '&&',
                    [
                        ['$1', '==', '(hl)'], '||', ['IS_INDIR', ['$1']]
                    ]
                ],
                '||',
                ['$1', '==', 'aa']
            ],
            'OFLAG': 15,
            'OLEVEL': 1,
            'REPLACE': ['push $1', 'pop $1'],
            'WITH': []
        })

    def test_parse_call(self):
        result = parser.parse_str('''
        OLEVEL: 1
        OFLAG: 27
        REPLACE {{
        ld a, $1
        }}
        IF {{
        !! !IS_INDIR($1)
        }}
        WITH {{
        }}
        ''')  # noqa
        self.assertDictEqual(result, {
            'IF': ['!', ['!', ['!', ['IS_INDIR', ['$1']]]]],
            'OFLAG': 27,
            'OLEVEL': 1,
            'REPLACE': ['ld a, $1'],
            'DEFINE': [],
            'WITH': []
        })

    def test_parse_chain_plus(self):
        result = parser.parse_str('''
        OLEVEL: 1
        OFLAG: 27
        REPLACE {{
        ld a, $1
        }}
        DEFINE {{
        $3 = $1 + $1 + $1
        }}
        WITH {{
        }}
        ''')  # noqa
        self.assertDictEqual(result, {
            'DEFINE': [['$3', parser.DefineLine(lineno=8, expr=parser.evaluator.Evaluator(
                [['$1', '+', '$1'], '+', '$1']
            ))]],
            'IF': [],
            'OFLAG': 27,
            'OLEVEL': 1,
            'REPLACE': ['ld a, $1'],
            'WITH': []
        })

    def test_parse_chain_parent(self):
        result = parser.parse_str('''
        OLEVEL: 1
        OFLAG: 27
        REPLACE {{
        ld a, $1
        }}
        DEFINE {{
        $3 = "(" + $1 + ")"
        }}
        WITH {{
        }}
        ''')  # noqa
        self.assertDictEqual(result, {
            'DEFINE': [['$3', parser.DefineLine(lineno=8, expr=parser.evaluator.Evaluator(
                [['(', '+', '$1'], '+', ')']
            ))]],
            'IF': [],
            'OFLAG': 27,
            'OLEVEL': 1,
            'REPLACE': ['ld a, $1'],
            'WITH': []
        })

    def test_parse_len(self):
        result = parser.parse_str('''
        OLEVEL: 1
        OFLAG: 31
        
        REPLACE {{
          $1 $2
          $3
        }}
        
        IF {{
            LEN($2) == 1
        }}
        
        WITH {{
        }}
        ''')  # noqa
        self.assertDictEqual(result, {
            'DEFINE': [],
            'IF': [['LEN', ['$2']], '==', '1'],
            'OFLAG': 31,
            'OLEVEL': 1,
            'REPLACE': ['$1 $2', '$3'],
            'WITH': []
        })

    def test_parse_len_2(self):
        result = parser.parse_str('''
        OLEVEL: 1
        OFLAG: 31

        REPLACE {{
          $1 $2
          $3
        }}

        IF {{
           (!IS_LABEL($3)) && (LEN($2) == 1)
        }}

        WITH {{
        }}
        ''')  # noqa
        self.assertDictEqual(result, {
            'DEFINE': [],
            'IF': [['!',
                    ['IS_LABEL', ['$3']]], '&&', [['LEN', ['$2']], '==', '1']],
            'OFLAG': 31,
            'OLEVEL': 1,
            'REPLACE': ['$1 $2', '$3'],
            'WITH': []
        })

    def test_define_concat(self):
        result = parser.parse_str('''
        OLEVEL: 1
        OFLAG: 31

        REPLACE {{
          ld $1, $2
          $3
        }}

        DEFINE {{
           $3 = "ld " + $2 + ", " + $1
        }}

        WITH {{
        }}
        ''')  # noqa
        self.assertDictEqual(result, {
            'DEFINE': [['$3',
                        parser.DefineLine(lineno=11, expr=parser.evaluator.Evaluator([[
                            ['ld ', '+', '$2'], '+', ', '], '+', '$1']))]],
            'IF': [],
            'OFLAG': 31,
            'OLEVEL': 1,
            'REPLACE': ['ld $1, $2', '$3'],
            'WITH': []
        })

    def test_reduce_unary(self):
        result = parser.parse_str(''';; Removes useless XOR a
        OLEVEL: 3
        OFLAG: 103
        REPLACE {{
          xor a
        }}
        IF {{
          (GVAL(a) == 0) && !IS_REQUIRED(f)
        }}
        WITH {{
        }}
        ''')
        self.assertDictEqual(result, {
            'DEFINE': [],
            'IF': [
                [['GVAL', ['a']], '==', '0'],
                '&&',
                ['!', ['IS_REQUIRED', ['f']]]
            ],
            'OFLAG': 103,
            'OLEVEL': 3,
            'REPLACE': ['xor a'],
            'WITH': []
        })

    def test_make_list(self):
        result = parser.parse_str('''
        OLEVEL: 2
        OFLAG: 28
        REPLACE {{
          $2
          pop $1
        }}
        IF {{
          !NEEDS($2, (sp, $1, af))
        }}
        WITH {{
          $2
          pop $1
        }}
        ''')
        assert result == {
            'OLEVEL': 2,
            'OFLAG': 28,
            'REPLACE': ['$2', 'pop $1'],
            'IF': [
                '!', [
                    'NEEDS', [
                        '$2', ',',
                        ['sp', ',', '$1', ',', 'af']
                    ]
                ]
            ],
            'WITH': ['$2', 'pop $1'],
            'DEFINE': []
        }

    def test_make_wrong_list_comma_comma(self):
        result = parser.parse_str('''
        OLEVEL: 2
        OFLAG: 28
        REPLACE {{
          $2
          pop $1
        }}
        IF {{
          !NEEDS($2, (sp, $1,,))
        }}
        WITH {{
          $2
          pop $1
        }}
        ''')
        assert result is None

    def test_make_wrong_list_comma(self):
        result = parser.parse_str('''
        OLEVEL: 2
        OFLAG: 28
        REPLACE {{
          $2
          pop $1
        }}
        IF {{
          !NEEDS($2, (sp, $1,))
        }}
        WITH {{
          $2
          pop $1
        }}
        ''')
        assert result is None

    def test_in_list(self):
        result = parser.parse_str('''
        OLEVEL: 2
        OFLAG: 28
        REPLACE {{
          $2
          pop $1
        }}
        IF {{
          !(INSTR($2) IN (jp, jr, ret, call, djnz, rst)) && !NEEDS($2, (sp, $1))
        }}
        WITH {{
          pop $1
          $2
        }}
        ''')
        assert result == {
            'OLEVEL': 2,
            'OFLAG': 28,
            'REPLACE': ['$2', 'pop $1'],
            'IF': [
                ['!', [
                    ['INSTR', ['$2']],
                    'IN',
                    ['jp', ',', 'jr', ',', 'ret', ',', 'call', ',', 'djnz', ',', 'rst']
                ]],
                '&&', ['!',
                       ['NEEDS',
                        ['$2', ',', ['sp', ',', '$1']]
                        ]
                       ]
            ],
            'WITH': ['pop $1', '$2'],
            'DEFINE': []
        }
