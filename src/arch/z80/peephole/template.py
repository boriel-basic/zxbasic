# -*- coding: utf-8 -*-

from typing import List

from .pattern import BasicLinePattern


class UnboundVarError(ValueError):
    pass


class LineTemplate(BasicLinePattern):
    """ Given a template line (i.e. 'push $1') and a dictionary
    of variables {'$1': value1, '$2': value2} replaces such variables
    with their values. '$$' is replaced by '$'. If any variable is unbound,
    an assertion is raised.
    """
    def filter(self, vars_=None) -> str:
        """ Applies a list of vars to the given pattern and returns the line
        """
        vars_ = vars_ or {}
        result = ''
        for tok in self.output:
            if len(tok) > 1 and tok[0] == '$':
                val = vars_.get(tok, None)
                if val is None:
                    raise UnboundVarError("Unbound variable {0}".format(tok))
                result += val
            else:
                result += tok

        return result.strip()

    def __repr__(self):
        return self.line


class BlockTemplate:
    """ Extends a Line template to a block of them
    """
    def __init__(self, lines):
        lines = [x.strip() for x in lines]
        self.templates = [LineTemplate(x) for x in lines if x]

    def filter(self, vars_=None) -> List[str]:
        return [y for y in [x.filter(vars_) for x in self.templates] if y]

    def __repr__(self):
        return repr([repr(x) for x in self.templates])
