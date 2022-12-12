#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------
from typing import NamedTuple

from src.api.constants import LoopType
from src.api.opcodestemps import OpcodesTemps
from src.api.type import PrimitiveType, Type

# ----------------------------------------------------------------------
# Simple global container for internal constants.
# Internal constants might be architecture dependant. They're set
# on module init (at __init__.py) on api.arch.<arch>/init.py
#
# Don't touch unless you know what are you doing
# ----------------------------------------------------------------------


class LoopInfo(NamedTuple):
    type: LoopType  # LOOP type: FOR, DO, LOOP, WHILE ...
    lineno: int  # line where this loop started
    var: str | None = None  # Var name used in FOR loop


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
LOOPS: list[LoopInfo] = []

# ----------------------------------------------------------------------
# Each new scope push the current LOOPS state and reset LOOPS. Upon
# scope exit, the previous LOOPS is restored and popped out of the
# META_LOOPS stack.
# ----------------------------------------------------------------------
META_LOOPS: list[list[LoopInfo]] = []

# ----------------------------------------------------------------------
# Number of parser (both syntactic & semantic) errors found. If not 0
# at the end, no asm output will be emitted.
# ----------------------------------------------------------------------
has_errors = 0  # Number of errors
has_warnings = 0  # Number of warnings

# ----------------------------------------------------------------------
# Default var type when not specified (implicit) an can't be guessed
# ----------------------------------------------------------------------
DEFAULT_TYPE: Type = PrimitiveType.float

# ----------------------------------------------------------------------
# Default variable type when not specified in DIM.
# 'auto' => try to guess and if not, fallback to DEFAULT_TYPE
# ----------------------------------------------------------------------
DEFAULT_IMPLICIT_TYPE: Type = PrimitiveType.unknown

# ----------------------------------------------------------------------
# Maximum number of errors to report before giving up.
# ----------------------------------------------------------------------
DEFAULT_MAX_SYNTAX_ERRORS = 20

# ----------------------------------------------------------------------
# The current filename being processed (changes with each #include)
# ----------------------------------------------------------------------
FILENAME: str = "(stdin)"  # name of current file being parsed

# ----------------------------------------------------------------------
# Global Symbol Table
# ----------------------------------------------------------------------
SYMBOL_TABLE = None  # Must be initialized with SymbolTable instance

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
INITS: set[str] = set([])

# ----------------------------------------------------------------------
# FUNCTIONS pending to translate after parsing stage
# ----------------------------------------------------------------------
FUNCTIONS = []

# ----------------------------------------------------------------------
# Parameter alignment. Must be set by arch.<arch>.__init__
# ----------------------------------------------------------------------
PARAM_ALIGN: int | None = None  # Set to None, so if not set will raise error

# ----------------------------------------------------------------------
# Data type used for array boundaries. Must be an integral
# ----------------------------------------------------------------------
BOUND_TYPE = None  # Set to None, so if not set will raise error

# ----------------------------------------------------------------------
# Data type used for elements size. Must be an integral
# ----------------------------------------------------------------------
SIZE_TYPE: Type = PrimitiveType.uByte

# ----------------------------------------------------------------------
# CORE namespace (for core runtime library, like FP Calc)
# ----------------------------------------------------------------------
CORE_NAMESPACE = ".core"

# ----------------------------------------------------------------------
# DATA Labels namespace
# ----------------------------------------------------------------------
DATAS_NAMESPACE = ".DATA"

# ----------------------------------------------------------------------
# LABEL Labels namespace
# ----------------------------------------------------------------------
LABELS_NAMESPACE = ".LABEL"  # *MUST* start with a DOT (.)

# ----------------------------------------------------------------------
# USER DATA LABELS
# ----------------------------------------------------------------------
ZXBASIC_USER_DATA = f"{CORE_NAMESPACE}.ZXBASIC_USER_DATA"
ZXBASIC_USER_DATA_LEN = f"{CORE_NAMESPACE}.ZXBASIC_USER_DATA_LEN"


# ----------------------------------------------------------------------
# Data Type used for string chars index. Must be an integral
# ----------------------------------------------------------------------
STR_INDEX_TYPE: Type = PrimitiveType.uInteger

# ----------------------------------------------------------------------
# MIN and MAX str slice index
# ----------------------------------------------------------------------
MIN_STRSLICE_IDX: int | None = None  # Min. string slicing position
MAX_STRSLICE_IDX: int | None = None  # Max. string slicing position

# ----------------------------------------------------------------------
# Type used internally for pointer and memory addresses
# ----------------------------------------------------------------------
PTR_TYPE: Type = PrimitiveType.uInteger

# ----------------------------------------------------------------------
# Character used for name mangling. Usually '_' or '.'
# ----------------------------------------------------------------------
MANGLE_CHR = "_"
NAMESPACE_SEPARATOR = "."

# ----------------------------------------------------------------------
# Prefix used in labels to mark the beginning of array data
# ----------------------------------------------------------------------
ARRAY_DATA_PREFIX = "__DATA__"

# ----------------------------------------------------------------------
# Default optimization level
# ----------------------------------------------------------------------
DEFAULT_OPTIMIZATION_LEVEL = 2  # Optimization level. Higher -> more optimized

# ----------------------------------------------------------------------
# DATA blocks
# ----------------------------------------------------------------------
DATAS = []
DATA_LABELS_REQUIRED = set()  # DATA labels used by RESTORE that must be emitted
DATA_LABELS = {}  # Maps declared labels to current data ptr
DATA_PTR_CURRENT = None
DATA_IS_USED = False
DATA_FUNCTIONS = []  # Counts the number of funcptrs emitted

# ----------------------------------------------------------------------
# Cache of Message errors to avoid repetition
# ----------------------------------------------------------------------
error_msg_cache: set[str] = set()


# ----------------------------------------------------------------------
# Warning options
# ----------------------------------------------------------------------

# Warning codes and whether they're enabled or not
ENABLED_WARNINGS: dict[str, bool] = {}

# Number of expected warnings (won't be issued)
EXPECTED_WARNINGS: int = 0
