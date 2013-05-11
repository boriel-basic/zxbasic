#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

# ------------------------------------------------------
# Common setup and configuration for all tools 
# ------------------------------------------------------

import sys

# The options container
import options


OPTIONS = options.Options()

OPTIONS.add_option_if_not_defined('outputFileName', str)
OPTIONS.add_option_if_not_defined('StdErrFileName', str)
OPTIONS.add_option_if_not_defined('Debug', int, 0)

# Default console redirections
OPTIONS.add_option_if_not_defined('stdin', file, sys.stdin)
OPTIONS.add_option_if_not_defined('stdout', file, sys.stdout)
OPTIONS.add_option_if_not_defined('stderr', file, sys.stderr)

