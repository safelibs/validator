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

from tools import ValidatorError, select_libraries
from tools.inventory import FORBIDDEN_PACKAGE_FIELDS, FORBIDDEN_SCHEMA_FIELDS, load_manifest


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
COMMAND_PATH_TOKEN_SEPARATORS_RE = re.compile(r"""[\s'"`;$|&(){}\[\]<>,]+""")
VALIDATOR_PATH_RE = re.compile(r"""/validator(?:/[^\s'"`;$|&(){}\[\]<>,]*)?""")
ALLOWED_TESTCASE_MANIFEST_FIELDS = {"schema_version", "library", "apt_packages", "testcases"}
SANITIZED_DEPENDENT_TOP_LEVEL_FIELDS = {"schema_version", "library", "dependents"}
SANITIZED_DEPENDENT_FIELDS = {
    "name",
    "source_package",
    "package",
    "binary_package",
    "packages",
    "description",
}
DEPENDENT_FIXTURE_FORBIDDEN_TERMS = ("safe", "unsafe", "excl" + "uded")
DEPENDENT_FIXTURE_FORBIDDEN_RE = re.compile(
    r"\b(?:" + "|".join(re.escape(term) for term in DEPENDENT_FIXTURE_FORBIDDEN_TERMS) + r")\b",
    re.IGNORECASE,
)
GENERIC_USAGE_DESCRIPTION_RE = re.compile(
    r"\b(?:dependent test|usage test|safe regression|regression test)\b",
    re.IGNORECASE,
)
APT_PACKAGE_TOKEN_CHARS = r"A-Za-z0-9.+-"


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


def _reject_unexpected_manifest_fields(payload: dict[str, Any], *, path: Path) -> None:
    unexpected = sorted(set(payload) - ALLOWED_TESTCASE_MANIFEST_FIELDS)
    if not unexpected:
        return
    for field_name in unexpected:
        if field_name in FORBIDDEN_PACKAGE_FIELDS or field_name.endswith("_packages"):
            raise ValidatorError(f"{path} contains forbidden package-list field: {field_name}")
        if field_name in FORBIDDEN_SCHEMA_FIELDS:
            raise ValidatorError(f"{path} contains forbidden schema field: {field_name}")
    raise ValidatorError(f"{path} testcase manifest contains unsupported fields: {', '.join(unexpected)}")


def _has_path_segment(value: str, segment: str) -> bool:
    return segment in PurePosixPath(value).parts


def _iter_command_path_candidates(value: str) -> list[str]:
    candidates: list[str] = []
    for token in COMMAND_PATH_TOKEN_SEPARATORS_RE.split(value):
        if not token:
            continue
        for assignment_part in token.split("="):
            candidates.extend(part for part in assignment_part.split(":") if part)
    for match in VALIDATOR_PATH_RE.finditer(value):
        candidates.extend(part for part in match.group(0).split(":") if part)
    return candidates


def _validate_command_element(value: str, *, path: Path, library: str) -> None:
    if "\0" in value:
        raise ValidatorError(f"command entries must not contain NUL bytes in {path}")
    if "\\" in value:
        raise ValidatorError(f"command entries must not contain backslashes in {path}: {value!r}")

    repo_root = Path(__file__).resolve().parents[1]
    repo_root_text = str(repo_root.resolve(strict=False))

    for candidate in _iter_command_path_candidates(value):
        if _has_path_segment(candidate, ".."):
            raise ValidatorError(f"command entries must not contain '..' path segments in {path}: {value!r}")
        if repo_root_text in candidate:
            raise ValidatorError(f"command entries must not use repository-host absolute paths in {path}: {value!r}")
        if candidate == "/validator" or candidate.startswith("/validator/"):
            allowed_prefix = f"/validator/tests/{library}/"
            if candidate.startswith(allowed_prefix):
                continue
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
        for field_name, value in (
            ("id", case_id),
            ("title", title),
            ("description", description),
        ):
            if GENERIC_USAGE_DESCRIPTION_RE.search(value):
                raise ValidatorError(
                    f"usage testcase {field_name} must describe client behavior without generic migration wording "
                    f"in {path}: {case_id}"
                )
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
    _reject_unexpected_manifest_fields(payload, path=path)

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


def _library_apt_packages(entry: dict[str, Any]) -> tuple[str, ...]:
    packages = entry.get("apt_packages")
    if not isinstance(packages, list) or not packages:
        raise ValidatorError(f"{entry.get('name', '<unknown>')} must define non-empty apt_packages")
    normalized: list[str] = []
    for package in packages:
        if not isinstance(package, str) or not package.strip():
            raise ValidatorError(f"{entry.get('name', '<unknown>')} apt_packages must be non-empty strings")
        normalized.append(package.strip())
    return tuple(normalized)


def _manifest_path_for(entry: dict[str, Any], *, tests_root: Path) -> Path:
    raw_path = _require_non_empty_string(entry.get("testcases"), field_name="testcases", path=tests_root)
    path = Path(raw_path)
    if path.is_absolute():
        return path
    if path.parts and path.parts[0] == tests_root.name:
        return Path(__file__).resolve().parents[1] / path
    return tests_root / path


def load_manifests(
    config: dict[str, Any],
    *,
    tests_root: Path,
    require_testcases: bool = True,
) -> dict[str, TestcaseManifest]:
    loaded: dict[str, TestcaseManifest] = {}
    libraries = config.get("libraries")
    if not isinstance(libraries, list) or not libraries:
        raise ValidatorError("config must define libraries")

    for entry in libraries:
        if not isinstance(entry, dict):
            raise ValidatorError("config libraries must be mappings")
        library = _require_non_empty_string(entry.get("name"), field_name="library name", path=tests_root)
        manifest = load_testcase_manifest(_manifest_path_for(entry, tests_root=tests_root), library=library)
        expected_packages = _library_apt_packages(entry)
        if manifest.apt_packages != expected_packages:
            raise ValidatorError(
                f"apt_packages mismatch for {library}: testcase manifest has {list(manifest.apt_packages)!r}, "
                f"repositories.yml has {list(expected_packages)!r}"
            )
        if require_testcases and not manifest.testcases:
            raise ValidatorError(f"selected library has zero testcases: {library}")
        loaded[library] = manifest
    return loaded


def _container_path_to_host_path(value: str, *, tests_root: Path, library: str) -> Path | None:
    prefix = f"/validator/tests/{library}/"
    if not value.startswith(prefix):
        return None
    relative = PurePosixPath(value.removeprefix(prefix))
    if relative.is_absolute() or _has_path_segment(relative.as_posix(), ".."):
        raise ValidatorError(f"container testcase path escapes library root for {library}: {value}")
    return tests_root / library / Path(*relative.parts)


def _validate_case_scripts(
    manifests: dict[str, TestcaseManifest],
    *,
    tests_root: Path,
    kind: str,
) -> None:
    for library, manifest in manifests.items():
        for testcase in manifest.testcases:
            if testcase.kind != kind:
                continue

            scripts: list[Path] = []
            for command_item in testcase.command:
                for candidate in _iter_command_path_candidates(command_item):
                    host_path = _container_path_to_host_path(
                        candidate,
                        tests_root=tests_root,
                        library=library,
                    )
                    if host_path is None:
                        continue
                    if f"/tests/cases/{kind}/" in candidate and candidate.endswith(".sh"):
                        scripts.append(host_path)

            if not scripts:
                raise ValidatorError(
                    f"{kind} testcase must execute a script under tests/cases/{kind}: "
                    f"{library}/{testcase.id}"
                )

            for script_path in scripts:
                try:
                    resolved = script_path.resolve(strict=True)
                except FileNotFoundError as exc:
                    raise ValidatorError(
                        f"missing {kind} testcase script for {library}/{testcase.id}: {script_path}"
                    ) from exc
                if not resolved.is_file():
                    raise ValidatorError(
                        f"{kind} testcase script must be a file for {library}/{testcase.id}: {script_path}"
                    )
                if not resolved.stat().st_mode & 0o111:
                    raise ValidatorError(
                        f"{kind} testcase script must be executable for {library}/{testcase.id}: {script_path}"
                    )


def validate_source_case_artifacts(
    manifests: dict[str, TestcaseManifest],
    *,
    tests_root: Path,
) -> None:
    _validate_case_scripts(manifests, tests_root=tests_root, kind="source")


def _load_dependent_fixture(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text())
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing dependent fixture: {path}") from exc
    except json.JSONDecodeError as exc:
        raise ValidatorError(f"invalid dependent fixture JSON at {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValidatorError(f"dependent fixture must be a JSON object: {path}")
    return payload


def _scan_for_forbidden_dependent_text(value: Any, *, path: Path) -> None:
    if isinstance(value, str):
        if DEPENDENT_FIXTURE_FORBIDDEN_RE.search(value):
            raise ValidatorError(f"dependent fixture contains forbidden historical vocabulary at {path}: {value!r}")
        return
    if isinstance(value, list):
        for item in value:
            _scan_for_forbidden_dependent_text(item, path=path)
        return
    if isinstance(value, dict):
        for key, item in value.items():
            if DEPENDENT_FIXTURE_FORBIDDEN_RE.search(str(key)):
                raise ValidatorError(f"dependent fixture contains forbidden historical key at {path}: {key!r}")
            _scan_for_forbidden_dependent_text(item, path=path)


def validate_sanitized_dependent_fixture(
    path: Path,
    *,
    library: str,
    used_clients: set[str],
) -> set[str]:
    payload = _load_dependent_fixture(path)
    top_level = set(payload)
    if top_level != SANITIZED_DEPENDENT_TOP_LEVEL_FIELDS:
        unexpected = sorted(top_level - SANITIZED_DEPENDENT_TOP_LEVEL_FIELDS)
        missing = sorted(SANITIZED_DEPENDENT_TOP_LEVEL_FIELDS - top_level)
        details = []
        if unexpected:
            details.append(f"unsupported fields: {', '.join(unexpected)}")
        if missing:
            details.append(f"missing fields: {', '.join(missing)}")
        raise ValidatorError(f"dependent fixture must use the compact phase 5 schema at {path}: {'; '.join(details)}")
    if payload.get("schema_version") != 1:
        raise ValidatorError(f"dependent fixture schema_version must be 1 at {path}")
    if payload.get("library") != library:
        raise ValidatorError(f"dependent fixture library mismatch at {path}: expected {library!r}")
    dependents = payload.get("dependents")
    if not isinstance(dependents, list) or not dependents:
        raise ValidatorError(f"dependent fixture dependents must be a non-empty list at {path}")

    _scan_for_forbidden_dependent_text(payload, path=path)

    identifiers: set[str] = set()
    for index, entry in enumerate(dependents):
        if not isinstance(entry, dict):
            raise ValidatorError(f"dependent fixture entries must be objects at {path}: index {index}")
        extra_fields = sorted(set(entry) - SANITIZED_DEPENDENT_FIELDS)
        if extra_fields:
            raise ValidatorError(
                f"dependent fixture entry contains unsupported fields at {path}: {', '.join(extra_fields)}"
            )
        packages = entry.get("packages", [])
        if "packages" in entry:
            if not isinstance(packages, list) or any(
                not isinstance(package, str) or not package.strip()
                for package in packages
            ):
                raise ValidatorError(f"dependent fixture packages must be a list of strings at {path}: index {index}")
        has_identifier = False
        for field_name in ("name", "source_package", "package", "binary_package"):
            value = entry.get(field_name)
            if value is None:
                continue
            if not isinstance(value, str) or not value.strip():
                raise ValidatorError(
                    f"dependent fixture {field_name} must be a non-empty string at {path}: index {index}"
                )
            identifiers.add(value.strip())
            has_identifier = True
        for package in packages:
            identifiers.add(package.strip())
            has_identifier = True
        description = entry.get("description")
        if description is not None and (not isinstance(description, str) or not description.strip()):
            raise ValidatorError(f"dependent fixture description must be a non-empty string at {path}: index {index}")
        if not has_identifier:
            raise ValidatorError(f"dependent fixture entry must expose an identifier at {path}: index {index}")

    missing_clients = sorted(used_clients - identifiers)
    if missing_clients:
        raise ValidatorError(
            f"dependent fixture does not cover usage client_application values for {library}: "
            f"{', '.join(missing_clients)}"
        )
    return identifiers


def _entry_identifiers(entry: dict[str, Any]) -> set[str]:
    identifiers: set[str] = set()
    for field_name in ("name", "source_package", "package", "binary_package"):
        _collect_string(identifiers, entry.get(field_name))
    _collect_string_list(identifiers, entry.get("packages"))
    return identifiers


def _packages_for_used_clients(payload: dict[str, Any], *, used_clients: set[str]) -> set[str]:
    packages: set[str] = set()
    dependents = payload.get("dependents")
    if not isinstance(dependents, list):
        return packages
    for entry in dependents:
        if not isinstance(entry, dict):
            continue
        if used_clients.isdisjoint(_entry_identifiers(entry)):
            continue
        for package in entry.get("packages", []):
            if isinstance(package, str) and package.strip():
                packages.add(package.strip())
    return packages


def _validate_dockerfile_installs_dependent_packages(
    *,
    tests_root: Path,
    library: str,
    fixture_payload: dict[str, Any],
    used_clients: set[str],
) -> None:
    packages = _packages_for_used_clients(fixture_payload, used_clients=used_clients)
    if not packages:
        return

    dockerfile = tests_root / library / "Dockerfile"
    try:
        dockerfile_text = dockerfile.read_text()
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing Dockerfile for dependent package validation: {dockerfile}") from exc

    missing = [
        package
        for package in sorted(packages)
        if not re.search(
            rf"(?<![{APT_PACKAGE_TOKEN_CHARS}]){re.escape(package)}(?![{APT_PACKAGE_TOKEN_CHARS}])",
            dockerfile_text,
        )
    ]
    if missing:
        raise ValidatorError(
            f"Dockerfile for {library} does not install dependent packages used by usage cases: "
            f"{', '.join(missing)}"
        )


def validate_usage_case_artifacts(
    manifests: dict[str, TestcaseManifest],
    *,
    tests_root: Path,
) -> None:
    _validate_case_scripts(manifests, tests_root=tests_root, kind="usage")
    for library, manifest in manifests.items():
        used_clients = {
            testcase.client_application
            for testcase in manifest.testcases
            if testcase.kind == "usage" and testcase.client_application is not None
        }
        if not used_clients:
            continue
        fixture_path = tests_root / library / "tests" / "fixtures" / "dependents.json"
        validate_sanitized_dependent_fixture(fixture_path, library=library, used_clients=used_clients)
        fixture_payload = _load_dependent_fixture(fixture_path)
        _validate_dockerfile_installs_dependent_packages(
            tests_root=tests_root,
            library=library,
            fixture_payload=fixture_payload,
            used_clients=used_clients,
        )


def testcase_result_sort_key(result: dict[str, Any]) -> tuple[str, str]:
    return (str(result.get("library") or ""), str(result.get("testcase_id") or ""))


def summarize_manifests(manifests: dict[str, TestcaseManifest]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for library in sorted(manifests):
        manifest = manifests[library]
        source_cases = sum(1 for testcase in manifest.testcases if testcase.kind == "source")
        usage_cases = sum(1 for testcase in manifest.testcases if testcase.kind == "usage")
        rows.append(
            {
                "library": library,
                "source_cases": source_cases,
                "usage_cases": usage_cases,
                "total_cases": len(manifest.testcases),
            }
        )
    return rows


def print_manifest_summary(manifests: dict[str, TestcaseManifest]) -> None:
    rows = summarize_manifests(manifests)
    print("library source usage total")
    for row in rows:
        print(f"{row['library']} {row['source_cases']} {row['usage_cases']} {row['total_cases']}")
    print(
        "TOTAL "
        f"{sum(row['source_cases'] for row in rows)} "
        f"{sum(row['usage_cases'] for row in rows)} "
        f"{sum(row['total_cases'] for row in rows)}"
    )


def build_parser() -> argparse.ArgumentParser:
    repo_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--tests-root", type=Path, default=repo_root / "tests")
    parser.add_argument("--library", action="append")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--check-manifest-only", action="store_true")
    parser.add_argument("--list-summary", action="store_true")
    parser.add_argument("--min-source-cases", type=int, default=0)
    parser.add_argument("--min-usage-cases", type=int, default=0)
    parser.add_argument("--min-cases", type=int, default=0)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if not args.check and not args.check_manifest_only and not args.list_summary:
        raise ValidatorError("one of --check, --check-manifest-only, or --list-summary is required")

    config = load_manifest(args.config)
    selected = select_libraries(config, args.library)
    selected_config = dict(config)
    selected_config["libraries"] = selected
    if args.min_source_cases < 0 or args.min_usage_cases < 0 or args.min_cases < 0:
        raise ValidatorError("case thresholds must be non-negative")

    if args.check or args.list_summary:
        manifests = load_manifests(selected_config, tests_root=args.tests_root)
        source_cases = sum(
            1
            for manifest in manifests.values()
            for testcase in manifest.testcases
            if testcase.kind == "source"
        )
        usage_cases = sum(
            1
            for manifest in manifests.values()
            for testcase in manifest.testcases
            if testcase.kind == "usage"
        )
        total_cases = sum(len(manifest.testcases) for manifest in manifests.values())
        if args.list_summary:
            print_manifest_summary(manifests)
        if not args.check:
            return 0
        validate_source_case_artifacts(manifests, tests_root=args.tests_root)
        validate_usage_case_artifacts(manifests, tests_root=args.tests_root)
        if args.min_source_cases and source_cases < args.min_source_cases:
            raise ValidatorError(f"source case threshold not met: {source_cases} < {args.min_source_cases}")
        if args.min_usage_cases and usage_cases < args.min_usage_cases:
            raise ValidatorError(f"usage case threshold not met: {usage_cases} < {args.min_usage_cases}")
        if args.min_cases and total_cases < args.min_cases:
            raise ValidatorError(f"case threshold not met: {total_cases} < {args.min_cases}")
        return 0

    load_manifests(selected_config, tests_root=args.tests_root, require_testcases=False)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
