#!/usr/bin/env python
# -*- coding: utf-8 -*-

import six
from . import global_
from . import errmsg

__doc__ = """Utils module contains many helpers for several task, like reading files
or path management"""


def read_txt_file(fname):
    """Reads a txt file, regardless of its encoding
    """
    encodings = ['utf-8', 'cp1252']
    with open(fname, 'rb') as f:
        content = bytes(f.read())

    for i in encodings:
        try:
            result = content.decode(i)
            if six.PY2:
                result = result.encode('utf-8')
            return result
        except UnicodeDecodeError:
            pass

    global_.FILENAME = fname
    errmsg.syntax_error(1, 'Invalid file encoding. Use one of: %s' % ', '.join(encodings))
    return ''


def open_file(fname, mode='rb', encoding='utf-8'):
    """ An open() wrapper for PY2 and PY3 which allows encoding
    :param fname: file name (string)
    :param mode: file mode (string) optional
    :param encoding: optional encoding (string). Ignored in python2 or if not in text mode
    :return: an open file handle
    """
    if six.PY2 or 't' not in mode:
        kwargs = {}
    else:
        kwargs = {'encoding': encoding}

    return open(fname, mode, **kwargs)
