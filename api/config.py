#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

# ------------------------------------------------------
# Common setup and configuration for all tools
# ------------------------------------------------------

import sys

# The options container
from . import options
from . import global_

OPTIONS = options.Options()

OPTIONS.add_option_if_not_defined('outputFileName', str)
OPTIONS.add_option_if_not_defined('StdErrFileName', str)
OPTIONS.add_option_if_not_defined('Debug', int, 0)

# Default console redirections
OPTIONS.add_option_if_not_defined('stdin', None, sys.stdin)
OPTIONS.add_option_if_not_defined('stdout', None, sys.stdout)
OPTIONS.add_option_if_not_defined('stderr', None, sys.stderr)

# ----------------------------------------------------------------------
# Default Options and Compilation Flags
#
# optimization -- Optimization level. Use -O flag to change.
# case_insensitive -- Whether user identifiers are case insensitive
#                          or not
# array_base -- Default array lower bound
# param_byref --Default paramameter passing. TRUE => By Reference
# ----------------------------------------------------------------------
OPTIONS.add_option_if_not_defined('optimization', int, 0)
OPTIONS.add_option_if_not_defined('case_insensitive', bool, False)
OPTIONS.add_option_if_not_defined('array_base', int, 0)
OPTIONS.add_option_if_not_defined('byref', bool, False)
OPTIONS.add_option_if_not_defined('max_syntax_errors', int, global_.DEFAULT_MAX_SYNTAX_ERRORS)
OPTIONS.add_option_if_not_defined('string_base', int, 0)
OPTIONS.add_option_if_not_defined('memory_map', str, None)
