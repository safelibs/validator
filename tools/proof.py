from __future__ import annotations

import json
import math
import re
from datetime import datetime
from pathlib import Path, PurePosixPath
from typing import Any

from tools import ValidatorError, select_libraries
from tools.testcases import Testcase, TestcaseManifest, load_manifests


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
OPTIONAL_RESULT_FIELDS = {"error"}
UTC_TIMESTAMP_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z$")
PROOF_STATUSES = {"passed", "failed"}


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


def _require_status(value: Any, *, source_path: Path) -> str:
    if not isinstance(value, str) or not value.strip() or value not in PROOF_STATUSES:
        raise ValidatorError(f"status must be passed or failed in {source_path}")
    return value


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


def load_result(path: Path, *, artifacts_root: Path, require_casts: bool = False) -> dict[str, Any]:
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
    extras = sorted(set(payload) - REQUIRED_RESULT_FIELDS - OPTIONAL_RESULT_FIELDS)
    if extras:
        raise ValidatorError(f"unsupported result fields in {path}: {', '.join(extras)}")

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

    _require_string_list(payload.get("tags"), field_name="tags", source_path=path)
    _require_string_list(payload.get("requires"), field_name="requires", source_path=path)
    command = _require_string_list(payload.get("command"), field_name="command", source_path=path)
    if not command:
        raise ValidatorError(f"command must be non-empty in {path}")
    apt_packages = _require_string_list(payload.get("apt_packages"), field_name="apt_packages", source_path=path)
    if not apt_packages:
        raise ValidatorError(f"apt_packages must be non-empty in {path}")

    _require_status(payload.get("status"), source_path=path)
    _require_utc_timestamp(payload.get("started_at"), field_name="started_at", source_path=path)
    _require_utc_timestamp(payload.get("finished_at"), field_name="finished_at", source_path=path)
    _require_nonnegative_number(
        payload.get("duration_seconds"),
        field_name="duration_seconds",
        source_path=path,
    )
    _require_int(payload.get("exit_code"), field_name="exit_code", source_path=path)
    override_debs_installed = _require_bool(
        payload.get("override_debs_installed"),
        field_name="override_debs_installed",
        source_path=path,
    )
    if override_debs_installed:
        raise ValidatorError(f"override_debs_installed must be false for proof generation in {path}")

    expected_result_path = f"results/{library}/{testcase_id}.json"
    expected_log_path = f"logs/{library}/{testcase_id}.log"
    expected_cast_path = f"casts/{library}/{testcase_id}.cast"

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

    if require_casts and payload.get("cast_path") is None:
        raise ValidatorError(f"cast_path is required when casts are required: {path}")
    if payload.get("cast_path") is not None:
        if payload.get("cast_path") != expected_cast_path:
            raise ValidatorError(f"cast_path must equal {expected_cast_path!r} for result path {path}")
        assert cast_target is not None
        if not cast_target.is_file():
            raise ValidatorError(f"missing cast referenced by {path}: {cast_target}")
        inspect_cast(cast_target)

    return payload


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


def _suite_from_manifest(manifest: dict[str, Any]) -> dict[str, str]:
    suite = manifest.get("suite")
    if not isinstance(suite, dict):
        raise ValidatorError("manifest must define suite")
    proof_suite: dict[str, str] = {}
    for field_name in ("name", "image", "apt_suite"):
        value = suite.get(field_name)
        if not isinstance(value, str) or not value.strip():
            raise ValidatorError(f"manifest suite must define non-empty {field_name}")
        proof_suite[field_name] = value
    return proof_suite


def _validate_exact_result_set(
    *,
    artifact_root: Path,
    testcase_manifest: TestcaseManifest,
) -> None:
    result_dir = artifact_root / "results" / testcase_manifest.library
    expected_ids = [testcase.id for testcase in testcase_manifest.testcases]
    expected_set = set(expected_ids)
    if len(expected_set) != len(expected_ids):
        raise ValidatorError(f"duplicate testcase ids for {testcase_manifest.library}")
    if not result_dir.is_dir():
        raise ValidatorError(f"missing result directory for {testcase_manifest.library}: {result_dir}")
    actual_ids = sorted(path.stem for path in result_dir.glob("*.json") if path.name != "summary.json")
    actual_set = set(actual_ids)
    duplicate_actual = sorted({case_id for case_id in actual_ids if actual_ids.count(case_id) > 1})
    if duplicate_actual:
        raise ValidatorError(
            f"duplicate result JSON files for {testcase_manifest.library}: {', '.join(duplicate_actual)}"
        )
    missing = sorted(expected_set - actual_set)
    unexpected = sorted(actual_set - expected_set)
    details: list[str] = []
    if missing:
        details.append(f"missing {', '.join(missing)}")
    if unexpected:
        details.append(f"unexpected {', '.join(unexpected)}")
    if details:
        raise ValidatorError(
            f"result JSON set for {testcase_manifest.library} must match testcase manifest exactly: "
            + "; ".join(details)
        )


def _case_proof(
    *,
    result: dict[str, Any],
    testcase: Testcase,
    artifact_root: Path,
    result_path: Path,
) -> dict[str, Any]:
    proof_row: dict[str, Any] = {
        "testcase_id": testcase.id,
        "title": testcase.title,
        "description": testcase.description,
        "kind": testcase.kind,
        "mode": "original",
        "client_application": testcase.client_application,
        "tags": list(testcase.tags),
        "requires": list(testcase.requires),
        "status": result["status"],
        "result_path": f"results/{result['library']}/{testcase.id}.json",
        "log_path": f"logs/{result['library']}/{testcase.id}.log",
        "cast_path": result.get("cast_path"),
        "duration_seconds": result["duration_seconds"],
        "exit_code": result["exit_code"],
    }
    if result.get("cast_path") is not None:
        cast_target = validate_artifact_relative_path(
            result["cast_path"],
            field_name="cast_path",
            artifacts_root=artifact_root,
            source_path=result_path,
        )
        assert cast_target is not None
        proof_row.update(inspect_cast(cast_target))
    return proof_row


def _library_totals(testcases: list[dict[str, Any]]) -> dict[str, int]:
    return {
        "cases": len(testcases),
        "source_cases": sum(1 for result in testcases if result["kind"] == "source"),
        "usage_cases": sum(1 for result in testcases if result["kind"] == "usage"),
        "passed": sum(1 for result in testcases if result["status"] == "passed"),
        "failed": sum(1 for result in testcases if result["status"] == "failed"),
        "casts": sum(1 for result in testcases if result["cast_path"] is not None),
    }


def build_proof(
    manifest: dict[str, Any],
    *,
    artifact_root: Path,
    tests_root: Path,
    libraries: list[str] | None = None,
    min_cases: int = 0,
    min_source_cases: int = 0,
    min_usage_cases: int = 0,
    require_casts: bool = False,
) -> dict[str, Any]:
    if min_cases < 0 or min_source_cases < 0 or min_usage_cases < 0:
        raise ValidatorError("case thresholds must be non-negative")

    selected_entries = select_libraries(manifest, libraries)
    selected_manifest = dict(manifest)
    selected_manifest["libraries"] = selected_entries
    testcase_manifests = load_manifests(selected_manifest, tests_root=tests_root)

    artifact_root = artifact_root.resolve(strict=False)
    proof_libraries: list[dict[str, Any]] = []
    totals = {
        "libraries": 0,
        "cases": 0,
        "source_cases": 0,
        "usage_cases": 0,
        "passed": 0,
        "failed": 0,
        "casts": 0,
    }

    for entry in selected_entries:
        library = str(entry["name"])
        testcase_manifest = testcase_manifests[library]
        _validate_exact_result_set(artifact_root=artifact_root, testcase_manifest=testcase_manifest)

        case_rows: list[dict[str, Any]] = []
        for testcase in testcase_manifest.testcases:
            result_path = artifact_root / "results" / library / f"{testcase.id}.json"
            result = load_result(result_path, artifacts_root=artifact_root, require_casts=require_casts)
            _validate_result_matches_testcase(
                result,
                testcase=testcase,
                testcase_manifest=testcase_manifest,
                result_path=result_path,
            )
            case_rows.append(
                _case_proof(
                    result=result,
                    testcase=testcase,
                    artifact_root=artifact_root,
                    result_path=result_path,
                )
            )

        library_totals = _library_totals(case_rows)
        proof_libraries.append(
            {
                "library": library,
                "apt_packages": list(testcase_manifest.apt_packages),
                "totals": library_totals,
                "testcases": case_rows,
            }
        )
        totals["libraries"] += 1
        for field_name in ("cases", "source_cases", "usage_cases", "passed", "failed", "casts"):
            totals[field_name] += library_totals[field_name]

    if min_cases and totals["cases"] < min_cases:
        raise ValidatorError(f"case threshold not met: {totals['cases']} < {min_cases}")
    if min_source_cases and totals["source_cases"] < min_source_cases:
        raise ValidatorError(f"source case threshold not met: {totals['source_cases']} < {min_source_cases}")
    if min_usage_cases and totals["usage_cases"] < min_usage_cases:
        raise ValidatorError(f"usage case threshold not met: {totals['usage_cases']} < {min_usage_cases}")

    return {
        "proof_version": 2,
        "suite": _suite_from_manifest(manifest),
        "totals": totals,
        "libraries": proof_libraries,
    }
