#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# --------------------------------------------
# KopyLeft (K) 2008
# by Jose M. Rodriguez de la Rosa
#
# This program is licensed under the
# GNU Public License v.3.0
#
# The code emission interface.
# --------------------------------------------

from abc import ABC, abstractmethod


class CodeEmitter(ABC):
    """The base code emission interface."""

    @abstractmethod
    def emit(
        self,
        output_filename: str,
        program_name: str,
        loader_bytes: bytearray,
        entry_point,
        program_bytes,
        aux_bin_blocks,
        aux_headless_bin_blocks,
    ):
        pass
