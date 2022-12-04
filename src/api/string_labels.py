#!/usr/bin/env python
# -*- coding: utf-8 -*-

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

__doc__ = """This module is a singleton instance that contains
a mapping of constant Strings to Labels.
"""
from collections import defaultdict

from src.api import tmp_labels

STRING_LABELS: dict[str, str] = defaultdict(tmp_labels.tmp_label)


def reset():
    """Initializes this module"""
    global STRING_LABELS
    STRING_LABELS.clear()


def add_string_label(string: str) -> str:
    """Maps ("folds") the given string, returning an unique label ID.
    This allows several constant labels to be initialized to the same address
    thus saving memory space.
    :param string: the string to map
    :return: the unique label ID
    """
    global STRING_LABELS
    return STRING_LABELS[string]
