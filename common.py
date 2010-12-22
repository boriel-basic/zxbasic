#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

# ------------------------------------------------------
# Common setup and configuration for all tools 
# ------------------------------------------------------

# The options container
from options import OPTIONS


OPTIONS.add_option_if_not_defined('outputFileName', str)
OPTIONS.add_option_if_not_defined('StdErrFileName', str)
OPTIONS.add_option_if_not_defined('Debug', int, 0)

