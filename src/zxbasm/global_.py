from typing import List

from src.api import global_ as gl

DOT = gl.NAMESPACE_SEPARATOR  # NAMESPACE separator
GLOBAL_NAMESPACE = DOT
NAMESPACE = GLOBAL_NAMESPACE  # Current namespace (defaults to ''). It's a prefix added to each global label
NAMESPACE_STACK: List[str] = []


def normalize_namespace(namespace: str) -> str:
    """Given a namespace (e.g. '.' or 'mynamespace' or '..a...b....c'),
    returns it in normalized form. That is:
        - always prefixed with a dot
        - no trailing dots
        - any double dots are converted to single dot (..my..namespace => .my.namespace)
        - one or more dots (e.g. '.', '..', '...') are converted to '.' (Global namespace)
    """
    namespace = DOT + DOT.join(x for x in namespace.split(DOT) if x)
    return namespace
