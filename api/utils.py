#!/usr/bin/env python
# -*- coding: utf-8 -*-

import six
from . import global_
from . import errmsg


__all__ = ['read_txt_file', 'open_file', 'sanitize_filename', 'flatten_list']

__doc__ = """Utils module contains many helpers for several task, like reading files
or path management"""


def read_txt_file(fname):
    """Reads a txt file, regardless of its encoding
    """
    encodings = ['utf-8-sig', 'cp1252']
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
