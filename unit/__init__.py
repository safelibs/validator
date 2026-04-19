from __future__ import annotations

import copy
import subprocess
from pathlib import Path
from typing import Any

import yaml

from tools.inventory import CANONICAL_APT_PACKAGES, LIBRARY_ORDER


def run_git(
    args: list[str],
    *,
    cwd: Path,
    capture_output: bool = False,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=cwd,
        text=True,
        check=check,
        capture_output=capture_output,
    )


def init_repo(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)
    run_git(["init"], cwd=path)
    run_git(["config", "user.name", "Test User"], cwd=path)
    run_git(["config", "user.email", "test@example.invalid"], cwd=path)


def write_file(path: Path, content: str | bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(content, bytes):
        path.write_bytes(content)
    else:
        path.write_text(content)


def commit_all(repo_root: Path, message: str = "commit") -> None:
    run_git(["add", "."], cwd=repo_root)
    run_git(["commit", "-m", message], cwd=repo_root)


def archive_config() -> dict[str, Any]:
    return {
        "name": "ubuntu-24.04-original-apt",
        "image": "ubuntu:24.04",
        "apt_suite": "noble",
    }


def inventory_config() -> dict[str, Any]:
    return {}


def repository_entry(
    name: str,
    *,
    apt_packages: list[str] | None = None,
) -> dict[str, Any]:
    packages = apt_packages or list(CANONICAL_APT_PACKAGES.get(name, ("demo-runtime", "demo-dev")))
    entry: dict[str, Any] = {
        "name": name,
        "apt_packages": packages,
        "testcases": f"tests/{name}/testcases.yml",
        "source_snapshot": f"tests/{name}/tests/tagged-port/original",
        "fixtures": {
            "dependents": f"tests/{name}/tests/fixtures/dependents.json",
        },
    }
    return entry


def write_manifest(
    path: Path,
    repositories: list[dict[str, Any]] | None = None,
    *,
    archive: dict[str, Any] | None = None,
    inventory: dict[str, Any] | None = None,
) -> None:
    del inventory
    data = {
        "schema_version": 2,
        "suite": copy.deepcopy(archive or archive_config()),
        "libraries": copy.deepcopy(repositories or [repository_entry(name) for name in LIBRARY_ORDER]),
    }
    path.write_text(yaml.safe_dump(data, sort_keys=False))
