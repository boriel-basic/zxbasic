#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
from collections import defaultdict, namedtuple

from src import api

from src.arch.zx48k.peephole import pattern, evaluator, template, parser

from src.arch.zx48k.peephole.parser import REG_IF, REG_REPLACE, REG_DEFINE, REG_WITH, O_LEVEL, O_FLAG


OptPattern = namedtuple('OptPattern',
                        ('level', 'flag', 'patt', 'cond', 'template', 'parsed', 'defines', 'fname'))


OPTS_PATH = os.path.join(os.path.dirname(__file__), 'opts')

# Global list of optimization patterns
PATTERNS = []
# Max len of any pattern read
MAXLEN = None


def read_opt(opt_path):
    """ Given a path to an opt file, parses it and returns an OptPattern
    object, or None if there were errors
    """
    global MAXLEN

    fpath = os.path.abspath(opt_path)
    if not os.path.isfile(fpath):
        return

    parsed_result = parser.parse_file(fpath)
    if parsed_result is None:
        return

    try:
        pattern_ = OptPattern(
            level=parsed_result[O_LEVEL],
            flag=parsed_result[O_FLAG],
            patt=pattern.BlockPattern(parsed_result[REG_REPLACE]),
            template=template.BlockTemplate(parsed_result[REG_WITH]),
            cond=evaluator.Evaluator(parsed_result[REG_IF]),
            parsed=parsed_result,
            defines=parsed_result[REG_DEFINE],
            fname=os.path.basename(fpath))

        for var_, define_ in pattern_.defines:
            if var_ in pattern_.patt.vars:
                api.errmsg.warning(define_.lineno, "variable '{0}' already defined in pattern".format(var_), fpath)
                api.errmsg.warning(define_.lineno, "this template will be ignored", fpath)
                return

    except (ValueError, KeyError, TypeError):
        api.errmsg.warning(1, "There is an error in this template and it will be ignored", fpath)
    else:
        MAXLEN = max(len(pattern_.patt), MAXLEN or 0)
        return pattern_


def read_opts(folder_path, result=None):
    """ Reads (and parses) all *.opt files from the given directory
    retaining only those with no errors.
    """
    if result is None:
        result = defaultdict(list)

    try:
        files_to_read = [f for f in os.listdir(folder_path) if f.endswith('.opt')]
    except (FileNotFoundError, NotADirectoryError, PermissionError):
        return result

    for fname in files_to_read:
        pattern_ = read_opt(os.path.join(folder_path, fname))
        if pattern_ is None:
            continue

        result.append(pattern_)

    result[:] = sorted(result, key=lambda x: x.flag)
    return result


def apply_match(asm_list, patterns_list, index=0):
    """ Tries to match optimization patterns against the given ASM list block, starting
    at offset `index` within that block.

    Only patterns having an O_LEVEL between o_min and o_max (both included) will be taken
    into account.

    :param asm_list: A list of asm instructions (will be changed)
    :param patterns_list: A list of OptPatterns to try against
    :param index: Index to start matching from (defaults to 0)
    :param o_min: Minimum O level to use (defaults to 0)
    :param o_max: Maximum O level to use (defaults to inf)
    :return: True if there was a match and asm_list code was changed
    """
    for p in patterns_list:
        match = p.patt.match(asm_list, start=index)
        if match is None:  # HINT: {} is also a valid match
            continue

        for var, defline in p.defines:
            match[var] = defline.expr.eval(match)

        if not p.cond.eval(match):
            continue

        # All patterns have matched successfully. Apply this pattern
        matched = asm_list[index: index + len(p.patt)]
        applied = p.template.filter(match)
        asm_list[index: index + len(p.patt)] = applied
        api.errmsg.info('pattern applied [{}:{}]'.format("%03i" % p.flag, p.fname))
        api.debug.__DEBUG__('matched: \n    {}'.format('\n    '.join(matched)), level=1)
        return True

    return False


def init():
    global PATTERNS
    global MAXLEN

    PATTERNS = []
    MAXLEN = 0


def main(list_of_directories=None):
    """ Initializes the module and load all the *.opt files
    containing patterns and parses them. Valid .opt files will be stored in
    PATTERNS
    """
    global PATTERNS
    global MAXLEN

    if MAXLEN:
        return

    init()

    if not list_of_directories:
        list_of_directories = [OPTS_PATH]

    for directory in list_of_directories:
        read_opts(directory, PATTERNS)


if __name__ == '__main__':
    main(sys.argv[1:])
