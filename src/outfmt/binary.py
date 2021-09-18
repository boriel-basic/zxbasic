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

from .codeemitter import CodeEmitter


class BinaryEmitter(CodeEmitter):
    """Writes compiled code as raw binary data."""

    def emit(
        self,
        output_filename,
        program_name,
        loader_bytes,
        entry_point,
        program_bytes,
        aux_bin_blocks,
        aux_headless_bin_blocks,
    ):
        """Emits resulting binary file."""
        with open(output_filename, "wb") as f:
            f.write(bytearray(program_bytes))
