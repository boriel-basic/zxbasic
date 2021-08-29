from typing import List

from src.api import global_ as gl


DOT = gl.NAMESPACE_SEPARATOR  # NAMESPACE separator
GLOBAL_NAMESPACE = DOT
NAMESPACE = GLOBAL_NAMESPACE  # Current namespace (defaults to ''). It's a prefix added to each global label
NAMESPACE_STACK: List[str] = []
