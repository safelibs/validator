from __future__ import annotations

from pathlib import Path


_REPO_ROOT = Path(__file__).resolve().parent
_GENERATED_WORKSPACE_ROOTS = (
    _REPO_ROOT / ".work",
    _REPO_ROOT / "artifacts" / ".workspace",
)


def _is_relative_to(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
    except ValueError:
        return False
    return True


def pytest_ignore_collect(collection_path: Path, config: object) -> bool:
    path = Path(collection_path).resolve(strict=False)
    return any(_is_relative_to(path, root) for root in _GENERATED_WORKSPACE_ROOTS)
