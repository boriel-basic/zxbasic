# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from collections.abc import Callable


class ClassProperty:
    """Decorator for class properties.
    Use @classproperty instead of @property to add properties
    to the class object.
    """

    def __init__(self, fget: Callable[[type], Callable]) -> None:
        self.fget = fget

    def __get__(self, owner_self, owner_cls: type):
        return self.fget(owner_cls)


def classproperty(fget: Callable[[type], Callable]) -> ClassProperty:
    """Use this function as the decorator in lowercase to follow Python conventions."""
    return ClassProperty(fget)
