from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    sys.dont_write_bytecode = True
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, write_json
from tools.fetch_port_debs import PortRepo, load_port_repos, port_repos_by_library, validate_port_repo
from tools.github_auth import effective_github_token


COMMIT_RE = re.compile(r"^[0-9a-f]{40}$")
CVE_ID_RE = re.compile(r"^CVE-\d{4}-\d{4,}$")


def _github_headers(*, accept: str) -> dict[str, str]:
    headers = {
        "Accept": accept,
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "safelibs-validator",
    }
    token = effective_github_token()
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def _github_request_bytes(url: str, *, accept: str) -> bytes:
    request = urllib.request.Request(url, headers=_github_headers(accept=accept))
    try:
        with urllib.request.urlopen(request) as response:
            return response.read()
    except urllib.error.HTTPError as exc:
        raise ValidatorError(f"GitHub API request failed for {url}: HTTP {exc.code}") from exc
    except urllib.error.URLError as exc:
        raise ValidatorError(f"GitHub API request failed for {url}: {exc.reason}") from exc


def _github_request_json(url: str) -> Any:
    raw = _github_request_bytes(url, accept="application/vnd.github+json")
    try:
        return json.loads(raw.decode("utf-8"))
    except ValueError as exc:
        raise ValidatorError(f"GitHub API response was not JSON for {url}: {exc}") from exc


def fetch_relevant_cves(repo: PortRepo) -> Any:
    url = (
        f"https://api.github.com/repos/{repo.name_with_owner}/contents/relevant_cves.json"
    )
    raw = _github_request_bytes(url, accept="application/vnd.github.raw")
    try:
        return json.loads(raw.decode("utf-8"))
    except ValueError as exc:
        raise ValidatorError(
            f"relevant_cves.json for {repo.name_with_owner} was not JSON: {exc}"
        ) from exc


def fetch_branch_commit(repo: PortRepo) -> str:
    url = f"https://api.github.com/repos/{repo.name_with_owner}/commits/{repo.default_branch}"
    payload = _github_request_json(url)
    if not isinstance(payload, dict):
        raise ValidatorError(f"commit payload must be an object for {repo.name_with_owner}")
    sha = payload.get("sha")
    if not isinstance(sha, str) or COMMIT_RE.fullmatch(sha) is None:
        raise ValidatorError(
            f"could not resolve commit for {repo.name_with_owner}@{repo.default_branch}"
        )
    return sha


def _walk_strings(value: Any) -> list[str]:
    found: list[str] = []
    if isinstance(value, str):
        if CVE_ID_RE.fullmatch(value):
            found.append(value)
    elif isinstance(value, dict):
        for inner in value.values():
            found.extend(_walk_strings(inner))
    elif isinstance(value, list):
        for inner in value:
            found.extend(_walk_strings(inner))
    return found


def normalize_cve_ids(payload: Any) -> list[str]:
    """Extract CVE-shaped strings from any of the known relevant_cves.json schemas.

    The union of every CVE-shaped string under any of:
      - relevant_cve_ids
      - relevant_cves[*].id, relevant_cves[*].cve_id
      - high_priority[*].cve_id
      - secondary[*].cve_id
    """
    found: set[str] = set()
    if not isinstance(payload, dict):
        return []

    relevant_ids = payload.get("relevant_cve_ids")
    if isinstance(relevant_ids, list):
        for item in relevant_ids:
            if isinstance(item, str) and CVE_ID_RE.fullmatch(item):
                found.add(item)

    relevant_cves = payload.get("relevant_cves")
    if isinstance(relevant_cves, list):
        for entry in relevant_cves:
            if isinstance(entry, dict):
                for key in ("id", "cve_id"):
                    candidate = entry.get(key)
                    if isinstance(candidate, str) and CVE_ID_RE.fullmatch(candidate):
                        found.add(candidate)

    for bucket_key in ("high_priority", "secondary"):
        bucket = payload.get(bucket_key)
        if isinstance(bucket, list):
            for entry in bucket:
                if isinstance(entry, dict):
                    candidate = entry.get("cve_id")
                    if isinstance(candidate, str) and CVE_ID_RE.fullmatch(candidate):
                        found.add(candidate)

    return sorted(found)


def _read_existing_snapshot(path: Path) -> Any:
    try:
        return json.loads(path.read_text())
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing port-cves snapshot: {path}") from exc
    except ValueError as exc:
        raise ValidatorError(f"invalid port-cves snapshot JSON at {path}: {exc}") from exc


def _read_existing_index_entry(index_path: Path, library: str) -> dict[str, Any] | None:
    if not index_path.is_file():
        return None
    try:
        payload = json.loads(index_path.read_text())
    except ValueError:
        return None
    if not isinstance(payload, dict):
        return None
    libraries = payload.get("libraries")
    if not isinstance(libraries, dict):
        return None
    entry = libraries.get(library)
    if isinstance(entry, dict):
        return entry
    return None


def _index_entry(
    repo: PortRepo,
    *,
    commit: str,
    cve_ids: list[str],
) -> dict[str, Any]:
    return {
        "name_with_owner": repo.name_with_owner,
        "default_branch": repo.default_branch,
        "commit": commit,
        "cve_count": len(cve_ids),
        "cve_ids": cve_ids,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port-repos", required=True, type=Path)
    parser.add_argument("--output-root", required=True, type=Path)
    parser.add_argument("--refresh", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    repos = load_port_repos(args.port_repos)
    by_library = port_repos_by_library(repos)
    for repo in repos:
        validate_port_repo(repo)

    output_root: Path = args.output_root
    output_root.mkdir(parents=True, exist_ok=True)
    index_path = output_root / "index.json"

    libraries_index: dict[str, dict[str, Any]] = {}
    for library in sorted(by_library):
        repo = by_library[library]
        snapshot_path = output_root / f"{library}.json"
        existing_entry = _read_existing_index_entry(index_path, library)

        if not args.refresh and snapshot_path.is_file() and existing_entry is not None:
            payload = _read_existing_snapshot(snapshot_path)
            commit = existing_entry.get("commit")
            if not isinstance(commit, str) or COMMIT_RE.fullmatch(commit) is None:
                commit = fetch_branch_commit(repo)
            cve_ids = normalize_cve_ids(payload)
            libraries_index[library] = _index_entry(repo, commit=commit, cve_ids=cve_ids)
            continue

        payload = fetch_relevant_cves(repo)
        commit = fetch_branch_commit(repo)
        write_json(snapshot_path, payload)
        cve_ids = normalize_cve_ids(payload)
        libraries_index[library] = _index_entry(repo, commit=commit, cve_ids=cve_ids)

    index_payload = {
        "schema_version": 1,
        "generated_at_utc": datetime.now(tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "libraries": libraries_index,
    }
    write_json(index_path, index_payload)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
