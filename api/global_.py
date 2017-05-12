#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Simple global container for internal constants.
# Internal constants might be architecture dependant. They're set
# on module init (at __init__.py) on api.arch.<arch>/init.py
#
# Don't touch unless you know what are you doing
# ----------------------------------------------------------------------

from .opcodestemps import OpcodesTemps
from .constants import TYPE

# ----------------------------------------------------------------------
# Initializes a singleton container
# ----------------------------------------------------------------------
optemps = OpcodesTemps()  # Must be initialized with OpcodesTemps()

# ----------------------------------------------------------------------
# PUSH / POP loops for taking into account which nested-loop level
# the parser is in. Each element of the list must be a t-uple. And
# each t-uple must have at least one element (a string), which contains
# which kind of loop the parser is in: e.g. 'FOR', 'WHILE', or 'DO'.
# Nested loops are appended at the end, and popped out on loop exit.
# ----------------------------------------------------------------------
LOOPS = []

# ----------------------------------------------------------------------
# Each new scope push the current LOOPS state and reset LOOPS. Upon
# scope exit, the previous LOOPS is restored and popped out of the
# META_LOOPS stack.
# ----------------------------------------------------------------------
META_LOOPS = []

# ----------------------------------------------------------------------
# Number of parser (both syntatic & semantic) errors found. If not 0
# at the end, no asm output will be emitted.
# ----------------------------------------------------------------------
has_errors = 0    # Number of errors
has_warnings = 0  # Number of warnings

# ----------------------------------------------------------------------
# Default var type when not specified (implicit) an can't be guessed
# ----------------------------------------------------------------------
DEFAULT_TYPE = TYPE.float_

# ----------------------------------------------------------------------
# Default variable type when not specified in DIM.
# 'auto' => try to guess and if not, fallback to DEFAULT_TYPE
# ----------------------------------------------------------------------
DEFAULT_IMPLICIT_TYPE = TYPE.auto  # Use TYPE.auto for smart type guessing

# ----------------------------------------------------------------------
# Maximum number of errors to report before giving up.
# ----------------------------------------------------------------------
DEFAULT_MAX_SYNTAX_ERRORS = 20

# ----------------------------------------------------------------------
# The current filename being processes (changes with each #include)
# ----------------------------------------------------------------------
FILENAME = '(stdin)'  # name of current file being parsed

# ----------------------------------------------------------------------
# Global Symbol Table
# ----------------------------------------------------------------------
SYMBOL_TABLE = None  # Must be initialized with SymbolTable()

# ----------------------------------------------------------------------
# Function calls pending to check
# Each scope pushes (prepends) an empty list
# ----------------------------------------------------------------------
FUNCTION_CALLS = []

# ----------------------------------------------------------------------
# Function level entry ID in which scope we are in. If the list
# is empty, we are at GLOBAL scope
# ----------------------------------------------------------------------
FUNCTION_LEVEL = []

# ----------------------------------------------------------------------
# Initialization routines to be called automatically at program start
# ----------------------------------------------------------------------
INITS = set([])

# ----------------------------------------------------------------------
# FUNCTIONS pending to translate after parsing stage
# ----------------------------------------------------------------------
FUNCTIONS = []

# ----------------------------------------------------------------------
# Parameter alignment. Must be set by arch.<arch>.__init__
# ----------------------------------------------------------------------
PARAM_ALIGN = None  # Set to None, so if not set will raise error

# ----------------------------------------------------------------------
# Data type used for array boundaries. Must be an integral
# ----------------------------------------------------------------------
BOUND_TYPE = None  # Set to None, so if not set will raise error

# ----------------------------------------------------------------------
# Data type used for elements size. Must be an integral
# ----------------------------------------------------------------------
SIZE_TYPE = None

# ----------------------------------------------------------------------
# Data Type used for string chars index. Must be an integral
# ----------------------------------------------------------------------
STR_INDEX_TYPE = None

# ----------------------------------------------------------------------
# MIN and MAX str slice index
# ----------------------------------------------------------------------
MIN_STRSLICE_IDX = None  # Min. string slicing position
MAX_STRSLICE_IDX = None  # Max. string slicing position

# ----------------------------------------------------------------------
# Type used internally for pointer and memory addresses
# ----------------------------------------------------------------------
PTR_TYPE = None
