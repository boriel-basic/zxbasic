# Runtime labels

from .namespace import NAMESPACE


class DataRestoreLabels:
    READ = f"{NAMESPACE}.__READ"
    RESTORE = f"{NAMESPACE}.__RESTORE"


REQUIRED_MODULES = {
    DataRestoreLabels.READ: "read_restore.asm",
    DataRestoreLabels.RESTORE: "read_restore.asm",
}
