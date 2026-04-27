from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import tempfile
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    # Direct CLI checks should not leave interpreter cache files in the source tree.
    sys.dont_write_bytecode = True
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, ensure_parent, run, select_libraries, write_json
from tools.github_auth import effective_github_token, git_env, github_git_url
from tools.inventory import load_manifest


COMMIT_RE = re.compile(r"^[0-9a-f]{40}$")
PHASE_TAG_RE = re.compile(r"^(?P<number>[0-9]+)-(?P<name>[A-Za-z0-9][A-Za-z0-9._-]*)$")
NATIVE_ARCHITECTURES = {"amd64", "all"}
LOCK_GENERATED_AT = "1970-01-01T00:00:00Z"


@dataclass(frozen=True)
class PortRepo:
    library: str
    name_with_owner: str
    url: str
    default_branch: str
    tag_ref: str


@dataclass(frozen=True)
class ResolvedPortDeb:
    library: str
    repository: str
    tag_ref: str
    commit: str
    release_tag: str
    package: str
    filename: str
    architecture: str
    sha256: str
    size: int
    asset_url: str | None
    browser_download_url: str | None


@dataclass(frozen=True)
class ResolvedPortRef:
    tag_ref: str
    commit: str
    minimum_tag_ref: str
    minimum_commit: str


class PortDebUnavailable(ValidatorError):
    pass


def _require_string(value: Any, *, field_name: str, context: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValidatorError(f"{context} must define non-empty {field_name}")
    return value.strip()


def load_port_repos(path: Path) -> list[PortRepo]:
    try:
        payload = json.loads(path.read_text())
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing port repository inventory: {path}") from exc
    except ValueError as exc:
        raise ValidatorError(f"invalid port repository inventory JSON at {path}: {exc}") from exc
    if not isinstance(payload, list):
        raise ValidatorError(f"port repository inventory must be a JSON list: {path}")

    repos: list[PortRepo] = []
    for index, entry in enumerate(payload, start=1):
        if not isinstance(entry, dict):
            raise ValidatorError(f"port repository entry #{index} must be an object")
        context = f"port repository entry #{index}"
        repos.append(
            PortRepo(
                library=_require_string(entry.get("library"), field_name="library", context=context),
                name_with_owner=_require_string(
                    entry.get("nameWithOwner"),
                    field_name="nameWithOwner",
                    context=context,
                ),
                url=_require_string(entry.get("url"), field_name="url", context=context),
                default_branch=_require_string(
                    entry.get("default_branch"),
                    field_name="default_branch",
                    context=context,
                ),
                tag_ref=_require_string(entry.get("tag_ref"), field_name="tag_ref", context=context),
            )
        )
    return repos


def port_repos_by_library(repos: list[PortRepo]) -> dict[str, PortRepo]:
    names = [repo.library for repo in repos]
    duplicates = sorted({name for name in names if names.count(name) > 1})
    if duplicates:
        raise ValidatorError(f"port repository inventory contains duplicate libraries: {', '.join(duplicates)}")
    return {repo.library: repo for repo in repos}


def validate_port_repo(repo: PortRepo) -> None:
    expected_repository = f"safelibs/port-{repo.library}"
    expected_url = f"https://github.com/{expected_repository}"
    expected_minimum_tag_ref = f"refs/tags/{repo.library}/04-test"
    if repo.name_with_owner != expected_repository:
        raise ValidatorError(
            f"port repository for {repo.library} must be {expected_repository!r}, "
            f"got {repo.name_with_owner!r}"
        )
    if repo.url != expected_url:
        raise ValidatorError(f"port repository URL for {repo.library} must be {expected_url!r}")
    if repo.tag_ref != expected_minimum_tag_ref:
        raise ValidatorError(
            f"port repository tag_ref for {repo.library} must be {expected_minimum_tag_ref!r}, "
            f"got {repo.tag_ref!r}"
        )


def parse_ls_remote_refs(stdout: str) -> dict[str, str]:
    refs: dict[str, str] = {}
    for line in stdout.splitlines():
        parts = line.split()
        if len(parts) != 2:
            continue
        commit, ref_name = parts
        refs[ref_name] = commit
    return refs


def require_commit(value: str | None, *, description: str) -> str:
    if value is None:
        raise ValidatorError(f"missing {description}")
    if COMMIT_RE.fullmatch(value) is None:
        raise ValidatorError(f"{description} did not resolve to a commit hash")
    return value


def resolve_tag_commit(repo: PortRepo, tag_ref: str | None = None) -> str:
    tag_ref = tag_ref or repo.tag_ref
    git_url = github_git_url(repo.name_with_owner)
    completed = run(
        ["git", "ls-remote", git_url, tag_ref, f"{tag_ref}^{{}}"],
        env=git_env(),
        capture_output=True,
    )
    refs = parse_ls_remote_refs(completed.stdout)
    commit = refs.get(f"{tag_ref}^{{}}") or refs.get(tag_ref)
    return require_commit(commit, description=f"tag {tag_ref} in {repo.name_with_owner}")


def release_tag_for_commit(commit: str) -> str:
    if COMMIT_RE.fullmatch(commit) is None:
        raise ValidatorError(f"invalid commit hash: {commit!r}")
    return f"build-{commit[:12]}"


def phase_tag_sort_key(repo: PortRepo, tag_ref: str) -> tuple[int, str] | None:
    prefix = f"refs/tags/{repo.library}/"
    if not tag_ref.startswith(prefix) or tag_ref.endswith("^{}"):
        return None
    tag_name = tag_ref.removeprefix(prefix)
    match = PHASE_TAG_RE.fullmatch(tag_name)
    if match is None:
        return None
    return int(match.group("number")), tag_name


def latest_qualifying_phase_tag_ref(repo: PortRepo) -> str:
    minimum_key = phase_tag_sort_key(repo, repo.tag_ref)
    if minimum_key is None:
        raise ValidatorError(f"port repository tag_ref for {repo.library} must be a phase tag")

    git_url = github_git_url(repo.name_with_owner)
    completed = run(
        ["git", "ls-remote", "--tags", git_url, f"refs/tags/{repo.library}/*"],
        env=git_env(),
        capture_output=True,
    )
    refs = parse_ls_remote_refs(completed.stdout)
    minimum_phase = minimum_key[0]
    candidates = [
        (key, tag_ref)
        for tag_ref in refs
        if (key := phase_tag_sort_key(repo, tag_ref)) is not None and key[0] >= minimum_phase
    ]
    if not candidates:
        raise PortDebUnavailable(
            f"no phase tags at or after {repo.tag_ref} were found in {repo.name_with_owner}"
        )
    return max(candidates, key=lambda item: item[0])[1]


def resolve_port_ref(repo: PortRepo) -> ResolvedPortRef:
    selected_tag_ref = latest_qualifying_phase_tag_ref(repo)
    selected_commit = resolve_tag_commit(repo, selected_tag_ref)
    minimum_commit = selected_commit if selected_tag_ref == repo.tag_ref else resolve_tag_commit(repo)
    return ResolvedPortRef(
        tag_ref=selected_tag_ref,
        commit=selected_commit,
        minimum_tag_ref=repo.tag_ref,
        minimum_commit=minimum_commit,
    )


def github_headers(*, accept: str, include_auth: bool = True) -> dict[str, str]:
    headers = {
        "Accept": accept,
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "safelibs-validator",
    }
    token = effective_github_token() if include_auth else ""
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def github_api_json(url: str) -> dict[str, Any]:
    request = urllib.request.Request(
        url,
        headers=github_headers(accept="application/vnd.github+json"),
    )
    try:
        with urllib.request.urlopen(request) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            raise PortDebUnavailable(f"GitHub API request failed for {url}: HTTP {exc.code}") from exc
        raise ValidatorError(f"GitHub API request failed for {url}: HTTP {exc.code}") from exc
    except urllib.error.URLError as exc:
        raise ValidatorError(f"GitHub API request failed for {url}: {exc.reason}") from exc
    except ValueError as exc:
        raise ValidatorError(f"GitHub API response was not JSON for {url}: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValidatorError(f"GitHub API response must be an object for {url}")
    return payload


def load_release(repo: PortRepo, release_tag: str) -> dict[str, Any]:
    url = f"https://api.github.com/repos/{repo.name_with_owner}/releases/tags/{release_tag}"
    return github_api_json(url)


def parse_deb_asset_name(filename: str) -> tuple[str, str] | None:
    if not filename.endswith(".deb"):
        return None
    parts = filename[:-4].split("_")
    if len(parts) < 3:
        return None
    package = parts[0]
    architecture = parts[-1]
    if not package or not architecture:
        return None
    return package, architecture


def selected_assets(
    *,
    release: dict[str, Any],
    canonical_packages: list[str],
    library: str,
) -> tuple[list[dict[str, Any]], list[str]]:
    assets = release.get("assets")
    if not isinstance(assets, list):
        raise ValidatorError(f"release for {library} must define an assets list")

    canonical_set = set(canonical_packages)
    selected_by_package: dict[str, dict[str, Any]] = {}
    for asset in assets:
        if not isinstance(asset, dict):
            continue
        filename = asset.get("name")
        if not isinstance(filename, str):
            continue
        parsed = parse_deb_asset_name(filename)
        if parsed is None:
            continue
        package, architecture = parsed
        if package not in canonical_set or architecture not in NATIVE_ARCHITECTURES:
            continue
        if package in selected_by_package:
            raise ValidatorError(f"release for {library} has duplicate native deb assets for {package}")
        selected_by_package[package] = asset

    selected = [selected_by_package[package] for package in canonical_packages if package in selected_by_package]
    if not selected:
        raise PortDebUnavailable(f"release for {library} did not contain any native canonical .deb assets")
    unported = [package for package in canonical_packages if package not in selected_by_package]
    return selected, unported


def clean_selected_library_debs(output_root: Path, library: str) -> Path:
    leaf = output_root / library
    leaf.mkdir(parents=True, exist_ok=True)
    for path in leaf.glob("*.deb"):
        if path.is_file() or path.is_symlink():
            path.unlink()
    return leaf


def _download_to_handle(url: str, handle, *, include_auth: bool) -> None:
    request = urllib.request.Request(
        url,
        headers=github_headers(accept="application/octet-stream", include_auth=include_auth),
    )
    with urllib.request.urlopen(request) as response:
        shutil.copyfileobj(response, handle)


def _asset_download_attempts(
    asset_url: str,
    browser_download_url: str | None,
) -> list[tuple[str, bool]]:
    if browser_download_url and not effective_github_token():
        return [(browser_download_url, False), (asset_url, True)]
    attempts = [(asset_url, True)]
    if browser_download_url:
        attempts.append((browser_download_url, False))
    return attempts


def download_asset(asset_url: str, target: Path, browser_download_url: str | None = None) -> None:
    ensure_parent(target)
    fd, temp_name = tempfile.mkstemp(prefix=f".{target.name}.", suffix=".tmp", dir=str(target.parent))
    temp_path = Path(temp_name)
    try:
        with os.fdopen(fd, "wb") as handle:
            errors: list[str] = []
            attempts = _asset_download_attempts(asset_url, browser_download_url)
            for index, (url, include_auth) in enumerate(attempts):
                handle.seek(0)
                handle.truncate()
                try:
                    _download_to_handle(url, handle, include_auth=include_auth)
                    break
                except urllib.error.HTTPError as exc:
                    errors.append(f"{url}: HTTP {exc.code}")
                    if index + 1 == len(attempts):
                        raise ValidatorError(
                            f"GitHub asset download failed for {'; fallback '.join(errors)}"
                        ) from exc
                except urllib.error.URLError as exc:
                    errors.append(f"{url}: {exc.reason}")
                    if index + 1 == len(attempts):
                        raise ValidatorError(
                            f"GitHub asset download failed for {'; fallback '.join(errors)}"
                        ) from exc
        temp_path.replace(target)
    except Exception:
        temp_path.unlink(missing_ok=True)
        raise


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def dpkg_field(path: Path, field_name: str) -> str:
    if shutil.which("dpkg-deb") is None:
        raise ValidatorError("dpkg-deb is required to verify downloaded .deb assets")
    completed = run(
        ["dpkg-deb", "--field", str(path), field_name],
        capture_output=True,
    )
    return completed.stdout.strip()


def verify_deb_fields(path: Path, *, package: str, architecture: str) -> None:
    actual_package = dpkg_field(path, "Package")
    actual_architecture = dpkg_field(path, "Architecture")
    if actual_package != package:
        raise ValidatorError(f"{path.name} Package field must be {package!r}, got {actual_package!r}")
    if actual_architecture != architecture:
        raise ValidatorError(
            f"{path.name} Architecture field must be {architecture!r}, got {actual_architecture!r}"
        )


def deb_lock_entry(deb: ResolvedPortDeb) -> dict[str, Any]:
    return {
        "package": deb.package,
        "filename": deb.filename,
        "architecture": deb.architecture,
        "sha256": deb.sha256,
        "size": deb.size,
        "asset_api_url": deb.asset_url,
        "browser_download_url": deb.browser_download_url,
    }


def resolve_library(
    *,
    repo: PortRepo,
    canonical_packages: list[str],
    output_root: Path,
) -> dict[str, Any]:
    validate_port_repo(repo)
    try:
        resolved_ref = resolve_port_ref(repo)
        release_tag = release_tag_for_commit(resolved_ref.commit)
        release = load_release(repo, release_tag)
        assets, unported = selected_assets(
            release=release,
            canonical_packages=canonical_packages,
            library=repo.library,
        )
    except PortDebUnavailable as exc:
        return {
            "library": repo.library,
            "repository": repo.name_with_owner,
            "url": repo.url,
            "tag_ref": repo.tag_ref,
            "commit": None,
            "release_tag": None,
            "debs": [],
            "unported_original_packages": list(canonical_packages),
            "port_unavailable_reason": str(exc),
        }
    leaf = clean_selected_library_debs(output_root, repo.library)

    selected_debs: list[ResolvedPortDeb] = []
    assets_by_package: dict[str, dict[str, Any]] = {}
    for asset in assets:
        parsed = parse_deb_asset_name(str(asset["name"]))
        assert parsed is not None
        package, _architecture = parsed
        assets_by_package[package] = asset

    for package in canonical_packages:
        asset = assets_by_package.get(package)
        if asset is None:
            continue
        filename = str(asset["name"])
        parsed = parse_deb_asset_name(filename)
        assert parsed is not None
        parsed_package, architecture = parsed
        asset_url = asset.get("url")
        if not isinstance(asset_url, str) or not asset_url:
            raise ValidatorError(f"release asset for {repo.library}/{filename} must define url")
        browser_download_url = asset.get("browser_download_url")
        if browser_download_url is not None and not isinstance(browser_download_url, str):
            raise ValidatorError(f"release asset for {repo.library}/{filename} has invalid browser_download_url")
        target = leaf / filename
        download_asset(asset_url, target, browser_download_url)
        verify_deb_fields(target, package=parsed_package, architecture=architecture)
        selected_debs.append(
            ResolvedPortDeb(
                library=repo.library,
                repository=repo.name_with_owner,
                tag_ref=resolved_ref.tag_ref,
                commit=resolved_ref.commit,
                release_tag=release_tag,
                package=parsed_package,
                filename=filename,
                architecture=architecture,
                sha256=file_sha256(target),
                size=target.stat().st_size,
                asset_url=asset_url,
                browser_download_url=browser_download_url,
            )
        )

    return {
        "library": repo.library,
        "repository": repo.name_with_owner,
        "url": repo.url,
        "tag_ref": resolved_ref.tag_ref,
        "commit": resolved_ref.commit,
        "release_tag": release_tag,
        "debs": [deb_lock_entry(deb) for deb in selected_debs],
        "unported_original_packages": unported,
    }


def build_lock(
    *,
    config_path: Path,
    port_repos_path: Path,
    output_root: Path,
    libraries: list[str] | None = None,
) -> dict[str, Any]:
    manifest = load_manifest(config_path)
    selected_entries = select_libraries(manifest, libraries)
    selected_names = [str(entry["name"]) for entry in selected_entries]
    repos = port_repos_by_library(load_port_repos(port_repos_path))
    missing = [name for name in selected_names if name not in repos]
    if missing:
        raise ValidatorError(f"missing port repositories for selected libraries: {', '.join(missing)}")
    manifest_names = {str(entry["name"]) for entry in manifest["libraries"]}
    unknown_repos = sorted(name for name in repos if name not in manifest_names)
    if unknown_repos:
        raise ValidatorError(f"port repository inventory contains unknown libraries: {', '.join(unknown_repos)}")

    output_root.mkdir(parents=True, exist_ok=True)
    lock_libraries = [
        resolve_library(
            repo=repos[str(entry["name"])],
            canonical_packages=list(entry["apt_packages"]),
            output_root=output_root,
        )
        for entry in selected_entries
    ]
    return {
        "schema_version": 1,
        "mode": "port-04-test",
        "generated_at": LOCK_GENERATED_AT,
        "source_config": config_path.as_posix(),
        "source_inventory": port_repos_path.as_posix(),
        "libraries": lock_libraries,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--port-repos", required=True, type=Path)
    parser.add_argument("--output-root", required=True, type=Path)
    parser.add_argument("--lock-output", required=True, type=Path)
    parser.add_argument("--library", action="append")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    lock = build_lock(
        config_path=args.config,
        port_repos_path=args.port_repos,
        output_root=args.output_root,
        libraries=args.library or None,
    )
    write_json(args.lock_output, lock)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
