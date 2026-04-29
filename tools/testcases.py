from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml

if __package__ in {None, ""}:
    # Direct CLI checks should not leave interpreter cache files in the source tree.
    sys.dont_write_bytecode = True
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
ALLOWED_TESTCASE_MANIFEST_FIELDS = {"schema_version", "library", "apt_packages"}
SANITIZED_DEPENDENT_TOP_LEVEL_FIELDS = {"schema_version", "library", "dependents"}
SANITIZED_DEPENDENT_FIELDS = {
    "name",
    "source_package",
    "package",
    "binary_package",
    "packages",
    "description",
}
GENERIC_USAGE_DESCRIPTION_RE = re.compile(
    r"\b(?:dependent test|usage test|regression test)\b",
    re.IGNORECASE,
)
APT_PACKAGE_TOKEN_CHARS = r"A-Za-z0-9.+-"

CASE_KINDS = ("source", "usage")
HEADER_DIRECTIVE_RE = re.compile(r"^#\s*@([a-z][a-z_-]*)\s*:\s*(.*)$")
REQUIRED_HEADER_FIELDS = {"title", "description", "timeout", "tags"}
ALLOWED_HEADER_FIELDS = REQUIRED_HEADER_FIELDS | {"testcase", "client"}


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


def _parse_header_blocks(script_path: Path) -> list[dict[str, str]]:
    blocks: list[dict[str, str]] = []
    current: dict[str, str] | None = None
    text = script_path.read_text()
    for raw_line in text.splitlines():
        line = raw_line.rstrip()
        if line.startswith("#!"):
            continue
        if not line:
            break
        if not line.startswith("#"):
            break
        match = HEADER_DIRECTIVE_RE.match(line)
        if match is None:
            # bare `#` (or other comment) inside header zone: separator only
            continue
        key, value = match.group(1), match.group(2).strip()
        if key not in ALLOWED_HEADER_FIELDS:
            raise ValidatorError(
                f"unknown @{key} directive in {script_path}; allowed: {sorted(ALLOWED_HEADER_FIELDS)}"
            )
        if key == "testcase":
            if current is not None:
                blocks.append(current)
            current = {"testcase": value}
            continue
        if current is None:
            raise ValidatorError(
                f"@{key} directive precedes @testcase in {script_path}"
            )
        if key in current:
            raise ValidatorError(
                f"duplicate @{key} directive for testcase {current.get('testcase')!r} in {script_path}"
            )
        current[key] = value
    if current is not None:
        blocks.append(current)
    return blocks


def _validate_header_block(
    block: dict[str, str],
    *,
    script_path: Path,
    library: str,
    kind: str,
    dependent_identifiers: set[str] | None,
) -> Testcase:
    case_id = validate_case_id(block.get("testcase", ""))

    missing = REQUIRED_HEADER_FIELDS - block.keys()
    if missing:
        raise ValidatorError(
            f"testcase {case_id} in {script_path} is missing directives: {sorted(missing)}"
        )

    title = block["title"].strip()
    if not title:
        raise ValidatorError(f"@title must be non-empty for {case_id} in {script_path}")
    description = block["description"].strip()
    if not description:
        raise ValidatorError(f"@description must be non-empty for {case_id} in {script_path}")

    timeout_text = block["timeout"].strip()
    try:
        timeout_seconds = int(timeout_text, 10)
    except ValueError as exc:
        raise ValidatorError(
            f"@timeout must be an integer for {case_id} in {script_path}: {timeout_text!r}"
        ) from exc
    if timeout_seconds < 1 or timeout_seconds > 7200:
        raise ValidatorError(
            f"@timeout must be between 1 and 7200 for {case_id} in {script_path}"
        )

    tags_text = block["tags"].strip()
    tags: tuple[str, ...] = ()
    if tags_text:
        parsed_tags = []
        for raw in tags_text.split(","):
            tag = raw.strip()
            if not tag:
                raise ValidatorError(
                    f"@tags entries must be non-empty for {case_id} in {script_path}"
                )
            parsed_tags.append(tag)
        tags = tuple(parsed_tags)

    client_text = block.get("client", "").strip()
    client_application: str | None = client_text or None

    if kind == "source" and client_application is not None:
        raise ValidatorError(
            f"source testcase must not define @client for {case_id} in {script_path}"
        )
    if kind == "usage":
        if client_application is None:
            raise ValidatorError(
                f"usage testcase must define @client for {case_id} in {script_path}"
            )
        for field_name, value in (("id", case_id), ("title", title), ("description", description)):
            if GENERIC_USAGE_DESCRIPTION_RE.search(value):
                raise ValidatorError(
                    f"usage testcase {field_name} must describe client behavior without "
                    f"generic migration wording for {case_id} in {script_path}"
                )
        if dependent_identifiers is not None and client_application not in dependent_identifiers:
            raise ValidatorError(
                f"@client {client_application!r} is not present in dependent fixture identifiers "
                f"for {library}: {script_path}"
            )

    return Testcase(
        id=case_id,
        title=title,
        description=description,
        kind=kind,
        command=[],  # filled in by caller once it knows the container path
        timeout_seconds=timeout_seconds,
        tags=tags,
        client_application=client_application,
    )


def _container_script_path(library: str, kind: str, script_path: Path, library_root: Path) -> str:
    rel = script_path.relative_to(library_root)
    return f"/validator/tests/{library}/{rel.as_posix()}"


def _discover_testcases(
    *,
    library: str,
    library_root: Path,
    dependent_identifiers: set[str] | None,
) -> list[Testcase]:
    cases: list[Testcase] = []
    for kind in CASE_KINDS:
        kind_dir = library_root / "tests" / "cases" / kind
        if not kind_dir.is_dir():
            continue
        for script_path in sorted(kind_dir.glob("*.sh")):
            if not script_path.is_file():
                continue
            blocks = _parse_header_blocks(script_path)
            if not blocks:
                raise ValidatorError(
                    f"testcase script has no @testcase header block: {script_path}"
                )
            container_path = _container_script_path(library, kind, script_path, library_root)
            for block in blocks:
                case = _validate_header_block(
                    block,
                    script_path=script_path,
                    library=library,
                    kind=kind,
                    dependent_identifiers=dependent_identifiers,
                )
                command = ["bash", container_path]
                if len(blocks) > 1:
                    command.append(case.id)
                cases.append(
                    Testcase(
                        id=case.id,
                        title=case.title,
                        description=case.description,
                        kind=case.kind,
                        command=command,
                        timeout_seconds=case.timeout_seconds,
                        tags=case.tags,
                        client_application=case.client_application,
                        requires=case.requires,
                    )
                )
    return cases


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

    library_root = path.parent
    dependent_path = library_root / "tests" / "fixtures" / "dependents.json"
    dependent_identifiers: set[str] | None = (
        load_dependent_identifiers(dependent_path) if dependent_path.is_file() else None
    )

    cases = _discover_testcases(
        library=library,
        library_root=library_root,
        dependent_identifiers=dependent_identifiers,
    )

    seen_ids: set[str] = set()
    for case in cases:
        if case.id in seen_ids:
            raise ValidatorError(f"duplicate testcase id for {library}: {case.id}")
        seen_ids.add(case.id)

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


def _validate_case_scripts(
    manifests: dict[str, TestcaseManifest],
    *,
    tests_root: Path,
    kind: str,
) -> None:
    for library, manifest in manifests.items():
        seen: set[Path] = set()
        for testcase in manifest.testcases:
            if testcase.kind != kind:
                continue
            container_path = next((c for c in testcase.command if c.endswith(".sh")), None)
            if container_path is None or not container_path.startswith(f"/validator/tests/{library}/"):
                raise ValidatorError(
                    f"{kind} testcase must execute a script under tests/cases/{kind}: "
                    f"{library}/{testcase.id}"
                )
            relative = container_path[len(f"/validator/tests/{library}/"):]
            host_path = tests_root / library / relative
            if host_path in seen:
                continue
            seen.add(host_path)
            try:
                resolved = host_path.resolve(strict=True)
            except FileNotFoundError as exc:
                raise ValidatorError(
                    f"missing {kind} testcase script for {library}/{testcase.id}: {host_path}"
                ) from exc
            if not resolved.is_file():
                raise ValidatorError(
                    f"{kind} testcase script must be a file for {library}/{testcase.id}: {host_path}"
                )
            if not resolved.stat().st_mode & 0o111:
                raise ValidatorError(
                    f"{kind} testcase script must be executable for {library}/{testcase.id}: {host_path}"
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
