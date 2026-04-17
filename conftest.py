from __future__ import annotations

import ctypes.util
from functools import lru_cache
from pathlib import Path


_REPO_ROOT = Path(__file__).resolve().parent
_GENERATED_WORKSPACE_ROOTS = (
    _REPO_ROOT / ".work",
    _REPO_ROOT / "artifacts" / ".workspace",
)
_LIBVIPS_NATIVE_PYTEST_ROOTS = (
    _REPO_ROOT / "tests" / "libvips" / "tests" / "tagged-port" / "original" / "test" / "test-suite",
    _REPO_ROOT
    / "tests"
    / "libvips"
    / "tests"
    / "tagged-port"
    / "safe"
    / "vendor"
    / "pyvips-3.1.1"
    / "tests",
)


@lru_cache(maxsize=1)
def _native_libvips_available() -> bool:
    return ctypes.util.find_library("vips") is not None


def _is_relative_to(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
    except ValueError:
        return False
    return True


def pytest_ignore_collect(collection_path: Path, config: object) -> bool:
    path = Path(collection_path).resolve(strict=False)
    if any(_is_relative_to(path, root) for root in _GENERATED_WORKSPACE_ROOTS):
        return True
    if _native_libvips_available():
        return False
    return any(_is_relative_to(path, root) for root in _LIBVIPS_NATIVE_PYTEST_ROOTS)
