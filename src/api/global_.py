# vim:ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------
from __future__ import annotations

from typing import TYPE_CHECKING, Final, NamedTuple

from src.api.constants import TYPE, LoopType
from src.api.opcodestemps import OpcodesTemps

if TYPE_CHECKING:
    from src.symbols.call import SymbolCALL
    from src.symbols.id_ import SymbolID


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
DEFAULT_TYPE = TYPE.float

# ----------------------------------------------------------------------
# Default variable type when not specified in DIM.
# 'auto' => try to guess and if not, fallback to DEFAULT_TYPE
# ----------------------------------------------------------------------
DEFAULT_IMPLICIT_TYPE = TYPE.unknown  # Use TYPE.auto for smart type guessing

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
FUNCTION_CALLS: list[SymbolCALL] = []

# ----------------------------------------------------------------------
# Function level entry ID in which scope we are in. If the list
# is empty, we are at GLOBAL scope
# ----------------------------------------------------------------------
FUNCTION_LEVEL = []

# ----------------------------------------------------------------------
# Initialization routines to be called automatically at program start
# ----------------------------------------------------------------------
INITS: set[str] = set()

# ----------------------------------------------------------------------
# FUNCTIONS pending to translate after parsing stage
# ----------------------------------------------------------------------
FUNCTIONS: list[SymbolID] = []

# ----------------------------------------------------------------------
# Parameter alignment. Must be set by arch.<arch>.__init__
# ----------------------------------------------------------------------
PARAM_ALIGN: int | None = None  # Set to None, so if not set will raise error

# ----------------------------------------------------------------------
# Data type used for array boundaries. Must be an integral
# ----------------------------------------------------------------------
BOUND_TYPE: TYPE  # Unset, so if not set will raise error

# ----------------------------------------------------------------------
# Data type used for elements size. Must be an integral type
# ----------------------------------------------------------------------
SIZE_TYPE: TYPE = TYPE.ubyte

# ----------------------------------------------------------------------
# CORE namespace (for core runtime stdlib, like FP Calc)
# ----------------------------------------------------------------------
CORE_NAMESPACE: Final[str] = ".core"

# ----------------------------------------------------------------------
# DATA Labels namespace
# ----------------------------------------------------------------------
DATAS_NAMESPACE: Final[str] = ".DATA"

# ----------------------------------------------------------------------
# LABEL Labels namespace
# ----------------------------------------------------------------------
LABELS_NAMESPACE: Final[str] = ".LABEL"  # *MUST* start with a DOT (.)

# ----------------------------------------------------------------------
# USER DATA LABELS
# ----------------------------------------------------------------------
ZXBASIC_USER_DATA: Final[str] = f"{CORE_NAMESPACE}.ZXBASIC_USER_DATA"
ZXBASIC_USER_DATA_LEN: Final[str] = f"{CORE_NAMESPACE}.ZXBASIC_USER_DATA_LEN"


# ----------------------------------------------------------------------
# Data Type used for string chars index. Must be an integral
# ----------------------------------------------------------------------
STR_INDEX_TYPE: TYPE = TYPE.uinteger

# ----------------------------------------------------------------------
# MIN and MAX str slice index
# ----------------------------------------------------------------------
MIN_STRSLICE_IDX: int | None = None  # Min. string slicing position
MAX_STRSLICE_IDX: int | None = None  # Max. string slicing position

# ----------------------------------------------------------------------
# Type used internally for pointer and memory addresses
# ----------------------------------------------------------------------
PTR_TYPE: TYPE  # Unset, so if not set will raise error

# ----------------------------------------------------------------------
# Character used for name mangling. Usually '_' or '.'
# ----------------------------------------------------------------------
MANGLE_CHR: Final[str] = "_"
NAMESPACE_SEPARATOR: Final[str] = "."

# ----------------------------------------------------------------------
# Prefix used in labels to mark the beginning of array data
# ----------------------------------------------------------------------
ARRAY_DATA_PREFIX: Final[str] = "__DATA__"

# ----------------------------------------------------------------------
# Default optimization level
# ----------------------------------------------------------------------
DEFAULT_OPTIMIZATION_LEVEL: Final[int] = 2  # Optimization level. Higher -> more optimized

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
