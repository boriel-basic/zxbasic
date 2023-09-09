from collections import UserDict

from .errors import DuplicatedLabelError
from .labelinfo import LabelInfo


class LabelsDict(UserDict[str, LabelInfo]):
    """A dictionary of labels where an existing label cannot be overwritten"""

    def __setitem__(self, key: str, value: LabelInfo) -> None:
        if key in self.data:
            raise DuplicatedLabelError(key)

        self.data[key] = value
