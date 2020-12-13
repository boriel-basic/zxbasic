#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import errno
import shelve
import signal

from functools import wraps

from typing import NamedTuple
from typing import List
from typing import Any
from typing import Optional
from typing import Callable
from typing import IO
from typing import Iterable

from . import constants
from . import global_
from . import errmsg
from . import check

from .. import symbols

__all__ = [
    'read_txt_file',
    'open_file',
    'sanitize_filename',
    'flatten_list',
    'timeout'
]

__doc__ = """Utils module contains many helpers for several task, like reading files
or path management"""

SHELVE_PATH = os.path.join(constants.ZXBASIC_ROOT, 'parsetab', 'tabs.dbm')
SHELVE = shelve.open(SHELVE_PATH)


class DataRef(NamedTuple):
    label: str
    datas: List[Any]


def read_txt_file(fname: str) -> str:
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


def open_file(fname: str, mode: str = 'rb', encoding: str = 'utf-8') -> IO[Any]:
    """ An open() wrapper for PY2 and PY3 which allows encoding
    :param fname: file name (string)
    :param mode: file mode (string) optional
    :param encoding: optional encoding (string). Ignored in python2 or if not in text mode
    :return: an open file handle
    """
    if 't' not in mode or not encoding:
        return open(fname, mode)

    return open(fname, mode, encoding=encoding)


def sanitize_filename(fname: str) -> str:
    """ Given a file name (string) returns it with back-slashes reversed.
    This is to make all BASIC programs compatible in all OSes
    """
    return fname.replace('\\', '/')


def current_data_label() -> str:
    """ Returns a data label to which all labels must point to, until
    a new DATA line is declared
    """
    return '__DATA__{0}'.format(len(global_.DATAS))


def flatten_list(x: Iterable[Any], iterables=(list, )) -> List[Any]:
    """ Flattens a nested iterable and returns it as a List.
    Nested iterables will be flattened recursively (default only nested lists)
    """
    result = []

    for elem in x:
        if not isinstance(elem, iterables):
            result.append(elem)
        else:
            result.extend(flatten_list(elem))

    return result


def parse_int(num: Optional[str]) -> Optional[int]:
    """ Given an integer number, return its value,
    or None if it could not be parsed.
    Allowed formats: DECIMAL, HEXA (0xnnn, $nnnn or nnnnh)
    An hexadecimal number is ambiguous if it starts with a letter (i.e. A0h can be a label),
    and won't be parsed. Such numbers must be prefixed with 0 digit (i.e. 0A0h)
    :param num: (string) the number to be parsed
    :return: an integer number or None if it could not be parsed
    """
    num = (num or "").strip().upper()
    if not num:
        return None

    base = 10
    if num[:2] == '0X':
        base = 16
    elif num[-1] == 'H':
        if num[0] not in '0123456789':
            return None
        base = 16
        num = num[:-1]
    elif num[0] == '$':
        base = 16
        num = num[1:]
    elif num[0] == '%':
        base = 2
        num = num[1:]
    elif num[-1] == 'B':
        if num[0] not in '01':
            return None
        base = 2
        num = num[:-1]

    try:
        return int(num, base)
    except ValueError:
        pass

    return None


def load_object(key: str) -> Any:
    return SHELVE[key] if key in SHELVE else None


def save_object(key: str, obj: Any) -> Any:
    SHELVE[key] = obj
    SHELVE.sync()
    return obj


def get_or_create(key: str, fn: Callable[[], Any]) -> Any:
    return load_object(key) or save_object(key, fn())


def get_final_value(symbol: symbols.SYMBOL) -> Any:
    assert check.is_static(symbol)
    result = symbol
    while hasattr(result, 'value'):
        result = result.value

    return result


def timeout(seconds=10, error_message=os.strerror(errno.ETIME)):
    def decorator(func):
        def _handle_timeout(signum, frame):
            raise TimeoutError(error_message)

        def wrapper(*args, **kwargs):
            signal.signal(signal.SIGALRM, _handle_timeout)
            signal.alarm(seconds)
            try:
                result = func(*args, **kwargs)
            finally:
                signal.alarm(0)
            return result

        return wraps(func)(wrapper)

    return decorator
