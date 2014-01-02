#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

import beep
from translator import *

import api.global_
from api.constants import TYPE


# -----------------------------------------
# Arch initialization setup
# -----------------------------------------
api.global_.PARAM_ALIGN = 2  # Z80 param align
api.global_.BOUND_TYPE = TYPE.uinteger
