# -*- coding: utf-8 -*-

from api.errors import Error


class DuplicatedLabelError(Error):
    """ Exception raised when a duplicated Label is found.
    This should never happen.
    """

    def __init__(self, label):
        Error.__init__(self, "Invalid mnemonic '%s'" % label)
        self.label = label
