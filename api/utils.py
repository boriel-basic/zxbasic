#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import shelve
from typing import NamedTuple, List, Any

from . import constants
from . import global_
from . import errmsg
from . import check

import symbols


__all__ = ['read_txt_file', 'open_file', 'sanitize_filename', 'flatten_list']

__doc__ = """Utils module contains many helpers for several task, like reading files
or path management"""

SHELVE_PATH = os.path.join(constants.ZXBASIC_ROOT, 'parsetab', 'tabs.dbm')
SHELVE = shelve.open(SHELVE_PATH)


class DataRef(NamedTuple):
    label: str
    datas: List[Any]


def read_txt_file(fname):
    """Reads a txt file, regardless of its encoding
    """
    encodings = ['utf-8-sig', 'cp1252']
    with open(fname, 'rb') as f:
        content = bytes(f.read())

    for i in encodings:
        try:
            result = content.decode(i)
            return result
        except UnicodeDecodeError:
            pass

    global_.FILENAME = fname
    errmsg.error(1, 'Invalid file encoding. Use one of: %s' % ', '.join(encodings))
    return ''


def open_file(fname, mode='rb', encoding='utf-8'):
    """ An open() wrapper for PY2 and PY3 which allows encoding
    :param fname: file name (string)
    :param mode: file mode (string) optional
    :param encoding: optional encoding (string). Ignored in python2 or if not in text mode
    :return: an open file handle
    """
    if 't' not in mode:
        kwargs = {}
    else:
        kwargs = {'encoding': encoding}

    return open(fname, mode, **kwargs)


def sanitize_filename(fname):
    """ Given a file name (string) returns it with back-slashes reversed.
    This is to make all BASIC programs compatible in all OSes
    """
    return fname.replace('\\', '/')


def current_data_label():
    """ Returns a data label to which all labels must point to, until
    a new DATA line is declared
    """
    return '__DATA__{0}'.format(len(global_.DATAS))


def flatten_list(x):
    result = []

    for l in x:
        if not isinstance(l, list):
            result.append(l)
        else:
            result.extend(flatten_list(l))

    return result


def parse_int(str_num):
    """ Given an integer number, return its value,
    or None if it could not be parsed.
    Allowed formats: DECIMAL, HEXA (0xnnn, $nnnn or nnnnh)
    :param str_num: (string) the number to be parsed
    :return: an integer number or None if it could not be parsedd
    """
    str_num = (str_num or "").strip().upper()
    if not str_num:
        return None

    base = 10
    if str_num.startswith('0X'):
        base = 16
        str_num = str_num[2:]
    if str_num.endswith('H'):
        base = 16
        str_num = str_num[:-1]
    if str_num.startswith('$'):
        base = 16
        str_num = str_num[1:]

    try:
        return int(str_num, base)
    except ValueError:
        return None


def load_object(key):
    return SHELVE[key] if key in SHELVE else None


def save_object(key, obj):
    SHELVE[key] = obj
    SHELVE.sync()
    return obj


def get_or_create(key, fn):
    return load_object(key) or save_object(key, fn())


def get_final_value(symbol: symbols.SYMBOL):
    assert check.is_static(symbol)
    result = symbol
    while hasattr(result, 'value'):
        result = result.value

    return result
