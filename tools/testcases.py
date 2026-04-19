from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any

import yaml

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, select_repositories
from tools.inventory import load_manifest


CASE_ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]{1,78}[a-z0-9]$")
SCALAR_DEPENDENT_KEYS = (
    "name",
    "source_package",
    "package",
    "binary_package",
    "runtime_package",
    "software_name",
    "slug",
)
LIST_DEPENDENT_KEYS = (
    "packages",
    "binary_examples",
    "related_packages",
    "used_by",
)
DEPENDENT_LIST_KEYS = (
    "dependents",
    "runtime_dependents",
    "build_time_dependents",
    "packages",
    "selected_applications",
)


@dataclass(frozen=True)
class Testcase:
    id: str
    title: str
    description: str
    kind: str
    command: list[str]
    timeout_seconds: int
    tags: tuple[str, ...]
    client_application: str | None = None
    requires: tuple[str, ...] = ()


@dataclass(frozen=True)
class TestcaseManifest:
    library: str
    schema_version: int
    apt_packages: tuple[str, ...]
    testcases: tuple[Testcase, ...]


def validate_case_id(value: str) -> str:
    if not isinstance(value, str) or not CASE_ID_RE.fullmatch(value):
        raise ValidatorError(
            "testcase id must match ^[a-z0-9][a-z0-9-]{1,78}[a-z0-9]$: "
            f"{value!r}"
        )
    return value


def _load_yaml_mapping(path: Path) -> dict[str, Any]:
    try:
        payload = yaml.safe_load(path.read_text())
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing testcase manifest: {path}") from exc
    except yaml.YAMLError as exc:
        raise ValidatorError(f"invalid testcase manifest YAML at {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValidatorError(f"testcase manifest must be a YAML mapping: {path}")
    return payload


def _require_non_empty_string(value: Any, *, field_name: str, path: Path) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValidatorError(f"{field_name} must be a non-empty string in {path}")
    return value.strip()


def _require_string_list(value: Any, *, field_name: str, path: Path, non_empty: bool = False) -> list[str]:
    if not isinstance(value, list):
        raise ValidatorError(f"{field_name} must be a list in {path}")
    if non_empty and not value:
        raise ValidatorError(f"{field_name} must be non-empty in {path}")
    normalized: list[str] = []
    for item in value:
        if not isinstance(item, str) or not item.strip():
            raise ValidatorError(f"{field_name} entries must be non-empty strings in {path}")
        normalized.append(item.strip())
    return normalized


def _has_path_segment(value: str, segment: str) -> bool:
    return segment in PurePosixPath(value).parts


def _validate_command_element(value: str, *, path: Path, library: str) -> None:
    if "\0" in value:
        raise ValidatorError(f"command entries must not contain NUL bytes in {path}")
    if "\\" in value:
        raise ValidatorError(f"command entries must not contain backslashes in {path}: {value!r}")
    if _has_path_segment(value, ".."):
        raise ValidatorError(f"command entries must not contain '..' path segments in {path}: {value!r}")

    repo_root = Path(__file__).resolve().parents[1]
    try:
        candidate = Path(value)
        if candidate.is_absolute() and str(candidate).startswith(str(repo_root.resolve(strict=False))):
            raise ValidatorError(f"command entries must not use repository-host absolute paths in {path}: {value!r}")
    except OSError:
        pass

    if value == "/validator" or value.startswith("/validator/"):
        allowed_prefix = f"/validator/tests/{library}/"
        if not value.startswith(allowed_prefix):
            raise ValidatorError(
                f"/validator command paths must stay under /validator/tests/{library}/ in {path}: {value!r}"
            )


def _validate_command(value: Any, *, path: Path, library: str) -> list[str]:
    command = _require_string_list(value, field_name="command", path=path, non_empty=True)
    first = command[0]
    if "/" in first and not PurePosixPath(first).is_absolute():
        raise ValidatorError(f"command first element must be an executable name or absolute path in {path}: {first!r}")
    for item in command:
        _validate_command_element(item, path=path, library=library)
    return command


def _collect_string(target: set[str], value: Any) -> None:
    if isinstance(value, str):
        stripped = value.strip()
        if stripped:
            target.add(stripped)


def _collect_string_list(target: set[str], value: Any) -> None:
    if isinstance(value, list):
        for item in value:
            _collect_string(target, item)


def extract_dependent_identifiers(payload: dict[str, Any]) -> set[str]:
    identifiers: set[str] = set()
    if not isinstance(payload, dict):
        raise ValidatorError("dependent fixture payload must be a JSON object")

    entries: list[dict[str, Any]] = []
    for key in DEPENDENT_LIST_KEYS:
        value = payload.get(key)
        if value is None:
            continue
        if not isinstance(value, list):
            raise ValidatorError(f"dependent fixture {key} must be a list")
        entries.extend(item for item in value if isinstance(item, dict))

    for entry in entries:
        for key in SCALAR_DEPENDENT_KEYS:
            _collect_string(identifiers, entry.get(key))
        for key in LIST_DEPENDENT_KEYS:
            _collect_string_list(identifiers, entry.get(key))

        package_dependencies = entry.get("package_dependencies")
        if isinstance(package_dependencies, list):
            for dependency in package_dependencies:
                if isinstance(dependency, dict):
                    _collect_string(identifiers, dependency.get("package"))

        dependency_paths = entry.get("dependency_paths")
        if isinstance(dependency_paths, list):
            for dependency in dependency_paths:
                if isinstance(dependency, dict):
                    _collect_string(identifiers, dependency.get("binary_package"))
                    _collect_string(identifiers, dependency.get("source_package"))

    return identifiers


def load_dependent_identifiers(path: Path) -> set[str]:
    try:
        payload = json.loads(path.read_text())
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing dependent fixture: {path}") from exc
    except json.JSONDecodeError as exc:
        raise ValidatorError(f"invalid dependent fixture JSON at {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValidatorError(f"dependent fixture must be a JSON object: {path}")
    return extract_dependent_identifiers(payload)


def _validate_testcase(
    payload: Any,
    *,
    path: Path,
    library: str,
    dependent_identifiers: set[str] | None,
) -> Testcase:
    if not isinstance(payload, dict):
        raise ValidatorError(f"testcase entries must be mappings in {path}")

    case_id = validate_case_id(_require_non_empty_string(payload.get("id"), field_name="id", path=path))
    title = _require_non_empty_string(payload.get("title"), field_name="title", path=path)
    description = _require_non_empty_string(
        payload.get("description"),
        field_name="description",
        path=path,
    )
    kind = _require_non_empty_string(payload.get("kind"), field_name="kind", path=path)
    if kind not in {"source", "usage"}:
        raise ValidatorError(f"kind must be source or usage in {path}: {case_id}")

    command = _validate_command(payload.get("command"), path=path, library=library)
    timeout_seconds = payload.get("timeout_seconds")
    if isinstance(timeout_seconds, bool) or not isinstance(timeout_seconds, int):
        raise ValidatorError(f"timeout_seconds must be an integer in {path}: {case_id}")
    if timeout_seconds < 1 or timeout_seconds > 7200:
        raise ValidatorError(f"timeout_seconds must be between 1 and 7200 in {path}: {case_id}")

    tags = tuple(_require_string_list(payload.get("tags", []), field_name="tags", path=path))
    requires = tuple(_require_string_list(payload.get("requires", []), field_name="requires", path=path))
    client_application_raw = payload.get("client_application")
    client_application = (
        None
        if client_application_raw is None
        else _require_non_empty_string(client_application_raw, field_name="client_application", path=path)
    )

    if kind == "source" and client_application is not None:
        raise ValidatorError(f"source testcase must not define client_application in {path}: {case_id}")
    if kind == "usage":
        if client_application is None:
            raise ValidatorError(f"usage testcase must define client_application in {path}: {case_id}")
        if dependent_identifiers is None:
            dependent_path = path.parent / "tests" / "fixtures" / "dependents.json"
            dependent_identifiers = load_dependent_identifiers(dependent_path)
        if client_application not in dependent_identifiers:
            raise ValidatorError(
                f"client_application {client_application!r} is not present in dependent fixture identifiers "
                f"for {library}: {path}"
            )

    return Testcase(
        id=case_id,
        title=title,
        description=description,
        kind=kind,
        command=command,
        timeout_seconds=timeout_seconds,
        tags=tags,
        client_application=client_application,
        requires=requires,
    )


def load_testcase_manifest(path: Path, *, library: str) -> TestcaseManifest:
    payload = _load_yaml_mapping(path)

    if payload.get("schema_version") != 1:
        raise ValidatorError(f"schema_version must be 1 in {path}")
    manifest_library = _require_non_empty_string(payload.get("library"), field_name="library", path=path)
    if manifest_library != library:
        raise ValidatorError(f"library mismatch in {path}: expected {library!r}, got {manifest_library!r}")

    apt_packages = tuple(
        _require_string_list(
            payload.get("apt_packages"),
            field_name="apt_packages",
            path=path,
            non_empty=True,
        )
    )

    raw_cases = payload.get("testcases")
    if not isinstance(raw_cases, list):
        raise ValidatorError(f"testcases must be a list in {path}")

    dependent_identifiers: set[str] | None = None
    if any(isinstance(item, dict) and item.get("kind") == "usage" for item in raw_cases):
        dependent_identifiers = load_dependent_identifiers(path.parent / "tests" / "fixtures" / "dependents.json")

    cases: list[Testcase] = []
    seen_ids: set[str] = set()
    for raw_case in raw_cases:
        testcase = _validate_testcase(
            raw_case,
            path=path,
            library=library,
            dependent_identifiers=dependent_identifiers,
        )
        if testcase.id in seen_ids:
            raise ValidatorError(f"duplicate testcase id for {library}: {testcase.id}")
        seen_ids.add(testcase.id)
        cases.append(testcase)

    return TestcaseManifest(
        library=library,
        schema_version=1,
        apt_packages=apt_packages,
        testcases=tuple(cases),
    )


def _repository_apt_packages(entry: dict[str, Any]) -> tuple[str, ...]:
    packages = entry.get("verify_packages")
    if not isinstance(packages, list) or not packages:
        raise ValidatorError(f"{entry.get('name', '<unknown>')} must define non-empty verify_packages")
    normalized: list[str] = []
    for package in packages:
        if not isinstance(package, str) or not package.strip():
            raise ValidatorError(f"{entry.get('name', '<unknown>')} verify_packages must be non-empty strings")
        normalized.append(package.strip())
    return tuple(normalized)


def load_manifests(config: dict[str, Any], *, tests_root: Path) -> dict[str, TestcaseManifest]:
    loaded: dict[str, TestcaseManifest] = {}
    repositories = config.get("repositories")
    if not isinstance(repositories, list) or not repositories:
        raise ValidatorError("config must define repositories")

    for entry in repositories:
        if not isinstance(entry, dict):
            raise ValidatorError("config repositories must be mappings")
        library = _require_non_empty_string(entry.get("name"), field_name="repository name", path=tests_root)
        manifest = load_testcase_manifest(tests_root / library / "testcases.yml", library=library)
        expected_packages = _repository_apt_packages(entry)
        if manifest.apt_packages != expected_packages:
            raise ValidatorError(
                f"apt_packages mismatch for {library}: testcase manifest has {list(manifest.apt_packages)!r}, "
                f"repositories.yml has {list(expected_packages)!r}"
            )
        if not manifest.testcases:
            raise ValidatorError(f"selected library has zero testcases: {library}")
        loaded[library] = manifest
    return loaded


def testcase_result_sort_key(result: dict[str, Any]) -> tuple[str, str]:
    return (str(result.get("library") or ""), str(result.get("testcase_id") or ""))


def build_parser() -> argparse.ArgumentParser:
    repo_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--tests-root", type=Path, default=repo_root / "tests")
    parser.add_argument("--library", action="append")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--check-manifest-only", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if not args.check and not args.check_manifest_only:
        raise ValidatorError("one of --check or --check-manifest-only is required")

    config = load_manifest(args.config)
    selected = select_repositories(config, args.library)
    selected_config = dict(config)
    selected_config["repositories"] = selected

    if args.check:
        load_manifests(selected_config, tests_root=args.tests_root)
        return 0

    for entry in selected:
        library = _require_non_empty_string(entry.get("name"), field_name="repository name", path=args.tests_root)
        manifest = load_testcase_manifest(args.tests_root / library / "testcases.yml", library=library)
        expected_packages = _repository_apt_packages(entry)
        if manifest.apt_packages != expected_packages:
            raise ValidatorError(
                f"apt_packages mismatch for {library}: testcase manifest has {list(manifest.apt_packages)!r}, "
                f"repositories.yml has {list(expected_packages)!r}"
            )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
