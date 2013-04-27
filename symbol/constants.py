#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

__all__ = ['ID_CLASSES', 'DEPRECATED_SUFFIXES', 'ID_TYPES',
    'TYPE_NAMES', 'NAME_TYPES', 'TYPE_SIZES', 'SUFFIX_TYPE']
    

# -------------------------------------------------
# Global constants
# -------------------------------------------------

# ----------------------------------------------------------------------
# Identifier Class (variable, function, label, array)
# ----------------------------------------------------------------------
ID_CLASSES = ('var', 'function', 'label', 'array')

# ----------------------------------------------------------------------
# Deprecated suffixes for variable names, such as "a$"
# ----------------------------------------------------------------------
DEPRECATED_SUFFIXES = ('$', '%', '&')

# ----------------------------------------------------------------------
# Identifier type
# i8 = Integer, 8 bits
# u8 = Unsigned, 8 bits and so on
# ----------------------------------------------------------------------
ID_TYPES = ('i8', 'u8', 'i16', 'u16', 'i32', 'u32', 'fixed', 'float', 'string')
TYPE_NAMES = { 'byte': 'i8', 'ubyte': 'u8', 'integer': 'i16', 'uinteger': 'u16', 'long': 'i32',
            'ulong': 'u32', 'fixed': 'fixed', 'float': 'float', 'string': 'string'}

NAME_TYPES = dict([(TYPE_NAMES[x], x) for x in TYPE_NAMES.keys()]) # The reverse of above

TYPE_SIZES = {'i8': 1, 'u8': 1, 'i16': 2, 'u16': 2, 'i32': 4, 'u32': 4,
             'fixed': 4, 'float': 5, 'string': 2, None: 0 }

# Maps suffix to types
SUFFIX_TYPE = {'$': 'string', '%': 'i16', '&': 'i32'}

