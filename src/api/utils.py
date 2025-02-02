import errno
import os
import shelve
import signal
from collections.abc import Callable, Iterable
from contextlib import contextmanager
from functools import wraps
from typing import IO, Any, TypeVar

from src.api import constants, errmsg, global_

__all__ = (
    "chdir",
    "first",
    "flatten_list",
    "open_file",
    "read_txt_file",
    "sanitize_filename",
    "timeout",
)

__doc__ = """Utils module contains many helpers for several task,
like reading files or path management"""

SHELVE_PATH = os.path.join(constants.ZXBASIC_ROOT, "parsetab", "tabs.dbm")
SHELVE = shelve.open(SHELVE_PATH)

T = TypeVar("T")


def first(iter_: Iterable[T], default: T | None = None) -> T | None:
    """Return the first element of an Iterable, or None if it's empty or
    there are no more elements to return."""
    return next(iter(iter_), default)


def sfirst(iter_: Iterable[T]) -> T:
    """Return the first element of an Iterable, or fails if it's empty"""
    return next(iter(iter_))


def read_txt_file(fname: str) -> str:
    """Reads a txt file, regardless of its encoding"""
    encodings = ["utf-8-sig", "cp1252"]
    with open(fname, "rb") as f:
        content = bytes(f.read())

    for i in encodings:
        try:
            result = content.decode(i)
            return result
        except UnicodeDecodeError:
            pass

    global_.FILENAME = fname
    errmsg.error(1, "Invalid file encoding. Use one of: %s" % ", ".join(encodings))
    return ""


def open_file(fname: str, mode: str = "rb", encoding: str = "utf-8") -> IO[Any]:
    """An open() wrapper for PY2 and PY3 which allows encoding
    :param fname: file name (string)
    :param mode: file mode (string) optional
    :param encoding: optional encoding (string). Ignored in python2 or if not in text mode
    :return: an open file handle
    """
    if "t" not in mode or not encoding:
        return open(fname, mode)

    return open(fname, mode, encoding=encoding)


def sanitize_filename(fname: str) -> str:
    """Given a file name (string) returns it with back-slashes reversed.
    This is to make all BASIC programs compatible in all OSes
    """
    return fname.replace("\\", "/")


def get_absolute_filename_path(fname: str) -> str:
    """Given a filename, if it does not start with '/' or '\', it
    will be returned a given absolute filename path
    """
    return os.path.realpath(os.path.expanduser(fname))


def get_relative_filename_path(fname: str, current_dir: str | None = None) -> str:
    """Given an absolute path, returns it relative to the current directory,
    that is, if the file is in the same folder or any of it children, only
    the path from the current folder onwards is returned. Otherwise, the
    absolute path is returned
    """
    fname_abs = get_absolute_filename_path(fname)
    current_path = get_absolute_filename_path(os.path.curdir if current_dir is None else current_dir)

    if not fname_abs.startswith(current_path):
        return fname_abs

    return fname_abs[len(current_path) :].lstrip(os.path.sep)


def current_data_label() -> str:
    """Returns a data label to which all labels must point to, until
    a new DATA line is declared
    """
    return f"{global_.DATAS_NAMESPACE}.__DATA__{len(global_.DATAS)}"


def flatten_list(x: Iterable[Any], iterables=(list,)) -> list[Any]:
    """Flattens a nested iterable and returns it as a List.
    Nested iterables will be flattened recursively (default only nested lists)
    """
    result = []

    for elem in x:
        if not isinstance(elem, iterables):
            result.append(elem)
        else:
            result.extend(flatten_list(elem))

    return result


def parse_int(num: str | None) -> int | None:
    """Given an integer number, return its value,
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
    if num[:2] == "0X":
        base = 16
    elif num[-1] == "H":
        if num[0] not in "0123456789":
            return None
        base = 16
        num = num[:-1]
    elif num[0] == "$":
        base = 16
        num = num[1:]
    elif num[0] == "%":
        base = 2
        num = num[1:]
    elif num[-1] == "B":
        if num[0] not in "01":
            return None
        base = 2
        num = num[:-1]

    try:
        return int(num, base)
    except ValueError:
        pass

    return None


def eval_to_num(expr: str) -> int | float | None:
    """Evaluates the expression and returns the result or None
    if it was non-numeric."""
    try:
        result = eval(expr, {}, {})
    except (NameError, SyntaxError, ValueError):
        return None

    if isinstance(result, (int, float)):
        return result

    return None


def load_object(key: str) -> Any:
    return SHELVE[key] if key in SHELVE else None


def save_object(key: str, obj: Any) -> Any:
    SHELVE[key] = obj
    SHELVE.sync()
    return obj


def get_or_create(key: str, fn: Callable[[], Any]) -> Any:
    return load_object(key) or save_object(key, fn())


def timeout(seconds: Callable[[], int] | int = 10, error_message=os.strerror(errno.ETIME)):
    def decorator(func):
        def _handle_timeout(signum, frame):
            raise TimeoutError(error_message)

        def wrapper(*args, **kwargs):
            signal.signal(signal.SIGALRM, _handle_timeout)
            signal.alarm(seconds() if isinstance(seconds, Callable) else seconds)
            try:
                result = func(*args, **kwargs)
            finally:
                signal.alarm(0)
            return result

        return wraps(func)(wrapper)

    return decorator


@contextmanager
def chdir(path: str):
    """Context manager to temporarily enter a directory, and return back
    to the original folder upon exit."""
    current_path = os.path.abspath(os.getcwd())

    try:
        os.chdir(path)
        yield

    finally:
        os.chdir(current_path)
