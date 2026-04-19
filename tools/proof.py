from __future__ import annotations

import json
import math
import re
from datetime import datetime
from pathlib import Path, PurePosixPath
from typing import Any

from tools import ValidatorError
from tools.testcases import Testcase, TestcaseManifest, load_manifests, testcase_result_sort_key


REQUIRED_RESULT_FIELDS = {
    "schema_version",
    "library",
    "mode",
    "testcase_id",
    "title",
    "description",
    "kind",
    "client_application",
    "tags",
    "requires",
    "status",
    "started_at",
    "finished_at",
    "duration_seconds",
    "result_path",
    "log_path",
    "cast_path",
    "exit_code",
    "command",
    "apt_packages",
    "override_debs_installed",
}
SUMMARY_FIELDS = {
    "schema_version",
    "library",
    "mode",
    "cases",
    "source_cases",
    "usage_cases",
    "passed",
    "failed",
    "casts",
    "duration_seconds",
}
UTC_TIMESTAMP_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z$")


def _reject_json_constant(value: str) -> None:
    raise ValueError(f"invalid JSON constant: {value}")


def _load_json_object(path: Path, *, description: str) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(), parse_constant=_reject_json_constant)
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing {description}: {path}") from exc
    except ValueError as exc:
        raise ValidatorError(f"invalid {description} JSON at {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValidatorError(f"{description} must be a JSON object: {path}")
    return payload


def _validate_existing_artifact_file_path(
    path: Path,
    *,
    field_name: str,
    artifacts_root: Path,
    source_path: Path,
) -> None:
    try:
        resolved = path.resolve(strict=True)
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing {field_name} in {source_path}: {path}") from exc
    try:
        resolved.relative_to(artifacts_root.resolve(strict=False))
    except ValueError as exc:
        raise ValidatorError(f"{field_name} must stay within the artifact root in {source_path}: {path}") from exc
    if not resolved.is_file():
        raise ValidatorError(f"{field_name} must be a file in {source_path}: {path}")


def _validate_no_duplicate_strings(values: list[str], *, field_name: str) -> None:
    seen: set[str] = set()
    duplicates: list[str] = []
    for value in values:
        if value in seen:
            duplicates.append(value)
        seen.add(value)
    if duplicates:
        raise ValidatorError(f"{field_name} must not contain duplicates: {', '.join(duplicates)}")


def validate_artifact_relative_path(
    relative_path: str | None,
    *,
    field_name: str,
    artifacts_root: Path,
    source_path: Path,
) -> Path | None:
    if relative_path is None:
        return None
    if not isinstance(relative_path, str) or not relative_path:
        raise ValidatorError(
            f"{field_name} must be a non-empty artifact-root-relative path in {source_path}"
        )
    if "\\" in relative_path:
        raise ValidatorError(f"{field_name} must use artifact-root-relative paths in {source_path}")

    parts = relative_path.split("/")
    if any(part in {"", ".", ".."} for part in parts):
        raise ValidatorError(f"{field_name} must be artifact-root-relative in {source_path}")

    pure_path = PurePosixPath(relative_path)
    if pure_path.is_absolute():
        raise ValidatorError(f"{field_name} must be artifact-root-relative in {source_path}")

    artifacts_root_resolved = artifacts_root.resolve(strict=False)
    target = (artifacts_root / Path(*pure_path.parts)).resolve(strict=False)
    try:
        target.relative_to(artifacts_root_resolved)
    except ValueError as exc:
        raise ValidatorError(f"{field_name} must stay within the artifact root in {source_path}") from exc
    return target


def _require_string(value: Any, *, field_name: str, source_path: Path) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValidatorError(f"{field_name} must be a non-empty string in {source_path}")
    return value


def _require_optional_string(value: Any, *, field_name: str, source_path: Path) -> str | None:
    if value is None:
        return None
    return _require_string(value, field_name=field_name, source_path=source_path)


def _require_utc_timestamp(value: Any, *, field_name: str, source_path: Path) -> str:
    text = _require_string(value, field_name=field_name, source_path=source_path)
    if not UTC_TIMESTAMP_RE.fullmatch(text):
        raise ValidatorError(f"{field_name} must be a UTC ISO-8601 string ending in Z in {source_path}")
    try:
        datetime.fromisoformat(text[:-1] + "+00:00")
    except ValueError as exc:
        raise ValidatorError(f"{field_name} must be a UTC ISO-8601 string ending in Z in {source_path}") from exc
    return text


def _require_nonnegative_number(value: Any, *, field_name: str, source_path: Path) -> int | float:
    if (
        isinstance(value, bool)
        or not isinstance(value, (int, float))
        or not math.isfinite(float(value))
        or value < 0
    ):
        raise ValidatorError(f"{field_name} must be a non-negative number in {source_path}")
    return value


def _require_int(value: Any, *, field_name: str, source_path: Path) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise ValidatorError(f"{field_name} must be an integer in {source_path}")
    return value


def _require_bool(value: Any, *, field_name: str, source_path: Path) -> bool:
    if not isinstance(value, bool):
        raise ValidatorError(f"{field_name} must be a boolean in {source_path}")
    return value


def _require_string_list(value: Any, *, field_name: str, source_path: Path) -> list[str]:
    if not isinstance(value, list):
        raise ValidatorError(f"{field_name} must be a list in {source_path}")
    normalized: list[str] = []
    for item in value:
        if not isinstance(item, str) or not item.strip():
            raise ValidatorError(f"{field_name} entries must be non-empty strings in {source_path}")
        normalized.append(item)
    return normalized


def _result_path_identity(path: Path, *, artifacts_root: Path) -> tuple[str, str] | None:
    absolute_path = path if path.is_absolute() else Path.cwd() / path
    try:
        relative = absolute_path.relative_to(artifacts_root.resolve(strict=False) / "results")
    except ValueError:
        return None
    if len(relative.parts) != 2 or relative.suffix != ".json" or relative.name == "summary.json":
        return None
    return relative.parts[0], relative.stem


def _summary_path_identity(path: Path, *, artifacts_root: Path) -> str | None:
    absolute_path = path if path.is_absolute() else Path.cwd() / path
    try:
        relative = absolute_path.relative_to(artifacts_root.resolve(strict=False) / "results")
    except ValueError:
        return None
    if len(relative.parts) != 2 or relative.name != "summary.json":
        return None
    return relative.parts[0]


def inspect_cast(cast_path: Path) -> dict[str, Any]:
    try:
        with cast_path.open(encoding="utf-8") as handle:
            header_line = handle.readline()
            if not header_line:
                raise ValidatorError(f"cast is empty: {cast_path}")
            try:
                header = json.loads(header_line, parse_constant=_reject_json_constant)
            except ValueError as exc:
                raise ValidatorError(f"invalid cast header JSON at {cast_path}: {exc}") from exc
            if not isinstance(header, dict):
                raise ValidatorError(f"cast header must be a JSON object: {cast_path}")
            if header.get("version") != 2:
                raise ValidatorError(f"cast header version must be 2: {cast_path}")
            for dimension in ("width", "height"):
                value = header.get(dimension)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    raise ValidatorError(f"cast header {dimension} must be a positive integer: {cast_path}")

            event_count = 0
            output_bytes = 0
            previous_timestamp: float | None = None
            final_timestamp = 0.0
            for line_number, line in enumerate(handle, start=2):
                try:
                    event = json.loads(line, parse_constant=_reject_json_constant)
                except ValueError as exc:
                    raise ValidatorError(
                        f"invalid cast event JSON at {cast_path}:{line_number}: {exc}"
                    ) from exc
                if not isinstance(event, list) or len(event) != 3:
                    raise ValidatorError(f"cast event must be a three-item list at {cast_path}:{line_number}")
                timestamp, event_type, payload = event
                if isinstance(timestamp, bool) or not isinstance(timestamp, (int, float)):
                    raise ValidatorError(f"cast event timestamp must be numeric at {cast_path}:{line_number}")
                timestamp_float = float(timestamp)
                if not math.isfinite(timestamp_float):
                    raise ValidatorError(f"cast event timestamp must be finite at {cast_path}:{line_number}")
                if timestamp_float < 0:
                    raise ValidatorError(f"cast event timestamp must be non-negative at {cast_path}:{line_number}")
                if previous_timestamp is not None and timestamp_float < previous_timestamp:
                    raise ValidatorError(f"cast event timestamps must be nondecreasing at {cast_path}:{line_number}")
                if event_type != "o":
                    raise ValidatorError(f"cast event type must be 'o' at {cast_path}:{line_number}")
                if not isinstance(payload, str):
                    raise ValidatorError(f"cast event payload must be a string at {cast_path}:{line_number}")
                previous_timestamp = timestamp_float
                final_timestamp = timestamp_float
                event_count += 1
                output_bytes += len(payload.encode("utf-8"))
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing cast: {cast_path}") from exc

    if event_count == 0:
        raise ValidatorError(f"cast must contain at least one output event: {cast_path}")
    return {
        "cast_events": event_count,
        "cast_bytes": output_bytes,
        "cast_duration_seconds": final_timestamp,
    }


def load_result(path: Path, *, artifacts_root: Path) -> dict[str, Any]:
    _validate_existing_artifact_file_path(
        path,
        field_name="result path",
        artifacts_root=artifacts_root,
        source_path=path,
    )
    payload = _load_json_object(path, description="result")
    missing = sorted(REQUIRED_RESULT_FIELDS - set(payload))
    if missing:
        raise ValidatorError(f"result schema mismatch in {path}: missing {', '.join(missing)}")

    if payload.get("schema_version") != 2:
        raise ValidatorError(f"schema_version must be 2 in {path}")
    library = _require_string(payload.get("library"), field_name="library", source_path=path)
    mode = _require_string(payload.get("mode"), field_name="mode", source_path=path)
    if mode != "original":
        raise ValidatorError(f"mode must be original in {path}")
    testcase_id = _require_string(payload.get("testcase_id"), field_name="testcase_id", source_path=path)
    _require_string(payload.get("title"), field_name="title", source_path=path)
    _require_string(payload.get("description"), field_name="description", source_path=path)
    kind = _require_string(payload.get("kind"), field_name="kind", source_path=path)
    if kind not in {"source", "usage"}:
        raise ValidatorError(f"kind must be source or usage in {path}")
    client_application = _require_optional_string(
        payload.get("client_application"),
        field_name="client_application",
        source_path=path,
    )
    if kind == "source" and client_application is not None:
        raise ValidatorError(f"source result client_application must be null in {path}")
    if kind == "usage" and client_application is None:
        raise ValidatorError(f"usage result client_application must be non-empty in {path}")

    tags = _require_string_list(payload.get("tags"), field_name="tags", source_path=path)
    requires = _require_string_list(payload.get("requires"), field_name="requires", source_path=path)
    command = _require_string_list(payload.get("command"), field_name="command", source_path=path)
    if not command:
        raise ValidatorError(f"command must be non-empty in {path}")
    apt_packages = _require_string_list(payload.get("apt_packages"), field_name="apt_packages", source_path=path)
    if not apt_packages:
        raise ValidatorError(f"apt_packages must be non-empty in {path}")

    status = _require_string(payload.get("status"), field_name="status", source_path=path)
    if status not in {"passed", "failed"}:
        raise ValidatorError(f"status must be passed or failed in {path}")
    _require_utc_timestamp(payload.get("started_at"), field_name="started_at", source_path=path)
    _require_utc_timestamp(payload.get("finished_at"), field_name="finished_at", source_path=path)
    _require_nonnegative_number(
        payload.get("duration_seconds"),
        field_name="duration_seconds",
        source_path=path,
    )
    _require_int(payload.get("exit_code"), field_name="exit_code", source_path=path)
    _require_bool(
        payload.get("override_debs_installed"),
        field_name="override_debs_installed",
        source_path=path,
    )

    result_target = validate_artifact_relative_path(
        payload.get("result_path"),
        field_name="result_path",
        artifacts_root=artifacts_root,
        source_path=path,
    )
    log_target = validate_artifact_relative_path(
        payload.get("log_path"),
        field_name="log_path",
        artifacts_root=artifacts_root,
        source_path=path,
    )
    cast_target = validate_artifact_relative_path(
        payload.get("cast_path"),
        field_name="cast_path",
        artifacts_root=artifacts_root,
        source_path=path,
    )

    identity = _result_path_identity(path, artifacts_root=artifacts_root)
    if identity is not None:
        path_library, path_case_id = identity
        if (library, testcase_id) != identity:
            raise ValidatorError(f"result identity does not match path in {path}")
        expected_result_path = f"results/{path_library}/{path_case_id}.json"
        expected_log_path = f"logs/{path_library}/{path_case_id}.log"
        if payload.get("result_path") != expected_result_path:
            raise ValidatorError(f"result_path must equal {expected_result_path!r} for result path {path}")
        if payload.get("log_path") != expected_log_path:
            raise ValidatorError(f"log_path must equal {expected_log_path!r} for result path {path}")
        assert result_target is not None
        if result_target.resolve(strict=False) != path.resolve(strict=False):
            raise ValidatorError(f"result_path must point at the source result JSON in {path}")

    assert log_target is not None
    if not log_target.is_file():
        raise ValidatorError(f"log_path does not exist for result path {path}: {log_target}")

    if cast_target is not None:
        expected_cast_path = f"casts/{library}/{testcase_id}.cast"
        if payload.get("cast_path") != expected_cast_path:
            raise ValidatorError(f"cast_path must equal {expected_cast_path!r} for result path {path}")
        if not cast_target.is_file():
            raise ValidatorError(f"missing cast referenced by {path}: {cast_target}")
        inspect_cast(cast_target)

    return payload


def load_summary(path: Path, *, artifacts_root: Path) -> dict[str, Any]:
    _validate_existing_artifact_file_path(
        path,
        field_name="summary path",
        artifacts_root=artifacts_root,
        source_path=path,
    )
    payload = _load_json_object(path, description="summary")
    missing = sorted(SUMMARY_FIELDS - set(payload))
    if missing:
        raise ValidatorError(f"summary schema mismatch in {path}: missing {', '.join(missing)}")
    extras = sorted(set(payload) - SUMMARY_FIELDS)
    if extras:
        raise ValidatorError(f"unsupported summary fields in {path}: {', '.join(extras)}")
    if payload.get("schema_version") != 2:
        raise ValidatorError(f"summary schema_version must be 2 in {path}")
    library = _require_string(payload.get("library"), field_name="library", source_path=path)
    if payload.get("mode") != "original":
        raise ValidatorError(f"summary mode must be original in {path}")
    identity = _summary_path_identity(path, artifacts_root=artifacts_root)
    if identity is not None and library != identity:
        raise ValidatorError(f"summary identity does not match path in {path}")
    for field_name in ("cases", "source_cases", "usage_cases", "passed", "failed", "casts"):
        value = _require_int(payload.get(field_name), field_name=field_name, source_path=path)
        if value < 0:
            raise ValidatorError(f"{field_name} must be non-negative in {path}")
    _require_nonnegative_number(
        payload.get("duration_seconds"),
        field_name="duration_seconds",
        source_path=path,
    )
    if payload["source_cases"] + payload["usage_cases"] != payload["cases"]:
        raise ValidatorError(f"source_cases plus usage_cases must equal cases in {path}")
    if payload["passed"] + payload["failed"] != payload["cases"]:
        raise ValidatorError(f"passed plus failed must equal cases in {path}")
    if payload["casts"] > payload["cases"]:
        raise ValidatorError(f"casts must not exceed cases in {path}")
    return payload


def _selected_manifest_entries(
    manifest: dict[str, Any],
    *,
    libraries: list[str] | None,
) -> list[dict[str, Any]]:
    repositories = manifest.get("repositories")
    if not isinstance(repositories, list) or not repositories:
        raise ValidatorError("manifest must define repositories")
    manifest_names = [str(entry.get("name")) for entry in repositories if isinstance(entry, dict)]
    if len(manifest_names) != len(repositories):
        raise ValidatorError("manifest repositories must be mappings with names")

    by_name = {name: entry for name, entry in zip(manifest_names, repositories)}
    if len(by_name) != len(manifest_names):
        raise ValidatorError("manifest repository names must be unique")

    if libraries is None:
        return list(repositories)

    for library in libraries:
        if not isinstance(library, str) or not library:
            raise ValidatorError(f"library selections must be non-empty strings: {library!r}")
    _validate_no_duplicate_strings(libraries, field_name="--library")
    unknown = [library for library in libraries if library not in by_name]
    if unknown:
        raise ValidatorError(f"unknown libraries in proof selection: {', '.join(unknown)}")
    selected_set = set(libraries)
    return [entry for entry in repositories if str(entry["name"]) in selected_set]


def _normalize_exclusions(
    excluded_libraries: dict[str, str] | None,
    *,
    selected_names: list[str],
) -> list[dict[str, str]]:
    if excluded_libraries is None:
        excluded_libraries = {}
    if not isinstance(excluded_libraries, dict):
        raise ValidatorError("excluded_libraries must be a mapping")

    selected_set = set(selected_names)
    unknown = [library for library in excluded_libraries if library not in selected_set]
    if unknown:
        raise ValidatorError(f"excluded libraries are outside the selected manifest set: {', '.join(unknown)}")

    normalized: list[dict[str, str]] = []
    for library in selected_names:
        if library not in excluded_libraries:
            continue
        note = excluded_libraries[library]
        if not isinstance(note, str) or not note.strip():
            raise ValidatorError(f"excluded library {library} requires a non-empty note")
        normalized.append({"library": library, "note": note})
    return normalized


def _require_result_field(
    result: dict[str, Any],
    *,
    field_name: str,
    expected_value: Any,
    result_path: Path,
) -> None:
    if result.get(field_name) != expected_value:
        raise ValidatorError(
            f"{field_name} mismatch in {result_path}: expected {expected_value!r}, got {result.get(field_name)!r}"
        )


def _validate_result_matches_testcase(
    result: dict[str, Any],
    *,
    testcase: Testcase,
    testcase_manifest: TestcaseManifest,
    result_path: Path,
) -> None:
    expected = {
        "library": testcase_manifest.library,
        "mode": "original",
        "testcase_id": testcase.id,
        "title": testcase.title,
        "description": testcase.description,
        "kind": testcase.kind,
        "client_application": testcase.client_application,
        "tags": list(testcase.tags),
        "requires": list(testcase.requires),
        "command": list(testcase.command),
        "apt_packages": list(testcase_manifest.apt_packages),
    }
    for field_name, expected_value in expected.items():
        _require_result_field(
            result,
            field_name=field_name,
            expected_value=expected_value,
            result_path=result_path,
        )


def _validate_summary_matches_results(
    summary: dict[str, Any],
    *,
    testcase_manifest: TestcaseManifest,
    results: list[dict[str, Any]],
    summary_path: Path,
) -> None:
    expected = {
        "library": testcase_manifest.library,
        "mode": "original",
        "cases": len(results),
        "source_cases": sum(1 for result in results if result["kind"] == "source"),
        "usage_cases": sum(1 for result in results if result["kind"] == "usage"),
        "passed": sum(1 for result in results if result["status"] == "passed"),
        "failed": sum(1 for result in results if result["status"] == "failed"),
        "casts": sum(1 for result in results if result["cast_path"] is not None),
    }
    for field_name, expected_value in expected.items():
        if summary.get(field_name) != expected_value:
            raise ValidatorError(
                f"summary {field_name} mismatch in {summary_path}: "
                f"expected {expected_value!r}, got {summary.get(field_name)!r}"
            )


def build_proof(
    manifest: dict[str, Any],
    *,
    artifact_root: Path,
    tests_root: Path,
    libraries: list[str] | None = None,
    excluded_libraries: dict[str, str] | None = None,
    record_casts_expected: bool = False,
    min_total_cases: int = 0,
) -> dict[str, Any]:
    if min_total_cases < 0:
        raise ValidatorError("case thresholds must be non-negative")

    selected_entries = _selected_manifest_entries(manifest, libraries=libraries)
    selected_names = [str(entry["name"]) for entry in selected_entries]
    normalized_exclusions = _normalize_exclusions(
        excluded_libraries,
        selected_names=selected_names,
    )
    excluded_set = {entry["library"] for entry in normalized_exclusions}
    included_entries = [entry for entry in selected_entries if str(entry["name"]) not in excluded_set]
    included_names = [str(entry["name"]) for entry in included_entries]

    if included_entries:
        included_manifest = dict(manifest)
        included_manifest["repositories"] = included_entries
        testcase_manifests = load_manifests(included_manifest, tests_root=tests_root)
    else:
        testcase_manifests = {}

    artifact_root = artifact_root.resolve(strict=False)
    proof_libraries: list[dict[str, Any]] = []
    totals = {
        "included_libraries": len(included_names),
        "excluded_libraries": len(normalized_exclusions),
        "cases": 0,
        "source_cases": 0,
        "usage_cases": 0,
        "passed": 0,
        "failed": 0,
        "casts": 0,
    }

    for entry in included_entries:
        library = str(entry["name"])
        testcase_manifest = testcase_manifests[library]
        case_proofs: list[dict[str, Any]] = []
        result_payloads: list[dict[str, Any]] = []

        for testcase in testcase_manifest.testcases:
            result_path = artifact_root / "results" / library / f"{testcase.id}.json"
            if not result_path.is_file():
                raise ValidatorError(f"missing result JSON for {library}/{testcase.id}: {result_path}")
            result = load_result(result_path, artifacts_root=artifact_root)
            _validate_result_matches_testcase(
                result,
                testcase=testcase,
                testcase_manifest=testcase_manifest,
                result_path=result_path,
            )
            if record_casts_expected and result.get("cast_path") is None:
                raise ValidatorError(f"cast_path is required when casts were recorded: {result_path}")
            cast_info: dict[str, Any] = {}
            if result.get("cast_path") is not None:
                cast_target = validate_artifact_relative_path(
                    result["cast_path"],
                    field_name="cast_path",
                    artifacts_root=artifact_root,
                    source_path=result_path,
                )
                assert cast_target is not None
                cast_info = inspect_cast(cast_target)

            result_payloads.append(result)
            case_proof: dict[str, Any] = {
                "testcase_id": testcase.id,
                "kind": testcase.kind,
                "client_application": testcase.client_application,
                "status": result["status"],
                "result_path": f"results/{library}/{testcase.id}.json",
                "log_path": f"logs/{library}/{testcase.id}.log",
                "cast_path": result.get("cast_path"),
            }
            case_proof.update(cast_info)
            case_proofs.append(case_proof)

        result_payloads.sort(key=testcase_result_sort_key)
        summary_path = artifact_root / "results" / library / "summary.json"
        summary = load_summary(summary_path, artifacts_root=artifact_root)
        _validate_summary_matches_results(
            summary,
            testcase_manifest=testcase_manifest,
            results=result_payloads,
            summary_path=summary_path,
        )

        totals["cases"] += summary["cases"]
        totals["source_cases"] += summary["source_cases"]
        totals["usage_cases"] += summary["usage_cases"]
        totals["passed"] += summary["passed"]
        totals["failed"] += summary["failed"]
        totals["casts"] += summary["casts"]

        proof_libraries.append(
            {
                "library": library,
                "summary_path": f"results/{library}/summary.json",
                "cases": case_proofs,
            }
        )

    if min_total_cases and totals["cases"] < min_total_cases:
        raise ValidatorError(f"total case threshold not met: {totals['cases']} < {min_total_cases}")

    return {
        "proof_version": 2,
        "mode": "original",
        "included_libraries": included_names,
        "excluded_libraries": normalized_exclusions,
        "totals": totals,
        "libraries": proof_libraries,
    }
