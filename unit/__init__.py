from __future__ import annotations

import copy
import subprocess
from pathlib import Path
from typing import Any

import yaml

from tools.inventory import (
    GH_REPO_LIST_COMMAND,
    GOAL_REPO_FAMILY,
    TAG_PROBE_RULE,
    VERIFIED_REPO_FAMILY,
)


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
        "suite": "noble",
        "component": "main",
        "origin": "SafeLibs",
        "label": "SafeLibs",
        "description": "Test repo for Ubuntu 24.04",
        "homepage": "https://example.invalid/project",
        "base_url": "https://example.invalid/validator/",
        "key_name": "safelibs",
        "image": "ubuntu:24.04",
        "install_packages": [
            "ca-certificates",
            "git",
            "python3",
        ],
    }


def inventory_config() -> dict[str, Any]:
    return {
        "verified_at": "2026-04-12T00:00:00Z",
        "gh_repo_list_command": GH_REPO_LIST_COMMAND,
        "tag_probe_rule": TAG_PROBE_RULE,
        "raw_snapshot": "inventory/github-repo-list.json",
        "filtered_snapshot": "inventory/github-port-repos.json",
        "goal_repo_family": GOAL_REPO_FAMILY,
        "verified_repo_family": VERIFIED_REPO_FAMILY,
    }


def repository_entry(
    name: str,
    *,
    imports: list[str],
    execution_strategy: str = "container-image",
    build: dict[str, Any] | None = None,
    verify_packages: list[str] | None = None,
) -> dict[str, Any]:
    entry: dict[str, Any] = {
        "name": name,
        "github_repo": f"safelibs/port-{name}",
        "ref": TAG_PROBE_RULE.format(library=name),
        "build": copy.deepcopy(build or {"mode": "safe-debian", "artifact_globs": ["*.deb"]}),
        "validator": {
            "sibling_repo": f"port-{name}",
            "execution_strategy": execution_strategy,
            "imports": list(imports),
            "import_excludes": [],
        },
        "fixtures": {
            "dependents": {"source": "copy-staged-root"},
            "relevant_cves": {"source": "copy-staged-root"},
        },
    }
    if verify_packages is not None:
        entry["verify_packages"] = list(verify_packages)
    return entry


def host_harness_repository_entry(
    name: str,
    *,
    imports: list[str],
    build: dict[str, Any] | None = None,
    verify_packages: list[str] | None = None,
) -> dict[str, Any]:
    return repository_entry(
        name,
        imports=imports,
        execution_strategy="host-harness",
        build=build,
        verify_packages=verify_packages,
    )


def write_manifest(
    path: Path,
    repositories: list[dict[str, Any]],
    *,
    archive: dict[str, Any] | None = None,
    inventory: dict[str, Any] | None = None,
) -> None:
    data = {
        "archive": copy.deepcopy(archive or archive_config()),
        "inventory": copy.deepcopy(inventory or inventory_config()),
        "repositories": copy.deepcopy(repositories),
    }
    path.write_text(yaml.safe_dump(data, sort_keys=False))
