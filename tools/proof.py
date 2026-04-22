from __future__ import annotations

import json
import math
import re
from datetime import datetime
from pathlib import Path, PurePosixPath
from typing import Any

from tools import ValidatorError, select_libraries
from tools.testcases import Testcase, TestcaseManifest, load_manifests


VALID_MODES = {"original", "port-04-test"}
BASE_REQUIRED_RESULT_FIELDS = {
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
PORT_REQUIRED_RESULT_FIELDS = {
    "port_repository",
    "port_tag_ref",
    "port_commit",
    "port_release_tag",
    "port_debs",
    "unported_original_packages",
    "override_installed_packages",
}
OPTIONAL_RESULT_FIELDS = {"error"}
PORT_UNAVAILABLE_FIELD = "port_unavailable_reason"
UTC_TIMESTAMP_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z$")
COMMIT_RE = re.compile(r"^[0-9a-f]{40}$")
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


def _require_mode(value: Any, *, source_path: Path) -> str:
    mode = _require_string(value, field_name="mode", source_path=source_path)
    if mode not in VALID_MODES:
        raise ValidatorError(f"mode must be original or port-04-test in {source_path}")
    return mode


def _require_port_debs(value: Any, *, source_path: Path, allow_empty: bool = False) -> list[dict[str, Any]]:
    if not isinstance(value, list) or (not value and not allow_empty):
        raise ValidatorError(f"port_debs must be a non-empty list in {source_path}")
    debs: list[dict[str, Any]] = []
    seen: set[str] = set()
    for item in value:
        if not isinstance(item, dict):
            raise ValidatorError(f"port_debs entries must be objects in {source_path}")
        deb = {
            "package": _require_string(item.get("package"), field_name="port_debs.package", source_path=source_path),
            "filename": _require_string(item.get("filename"), field_name="port_debs.filename", source_path=source_path),
            "architecture": _require_string(
                item.get("architecture"),
                field_name="port_debs.architecture",
                source_path=source_path,
            ),
            "sha256": _require_string(item.get("sha256"), field_name="port_debs.sha256", source_path=source_path),
            "size": _require_int(item.get("size"), field_name="port_debs.size", source_path=source_path),
        }
        if deb["architecture"] not in {"amd64", "all"}:
            raise ValidatorError(f"port_debs architecture must be amd64 or all in {source_path}")
        if deb["package"] in seen:
            raise ValidatorError(f"port_debs package entries must be unique in {source_path}")
        seen.add(deb["package"])
        if deb["size"] < 0:
            raise ValidatorError(f"port_debs size must be non-negative in {source_path}")
        debs.append(deb)
    return debs


def _require_override_installed_packages(
    value: Any,
    *,
    source_path: Path,
    allow_empty: bool = False,
) -> list[dict[str, str]]:
    if not isinstance(value, list) or (not value and not allow_empty):
        raise ValidatorError(f"override_installed_packages must be a non-empty list in {source_path}")
    records: list[dict[str, str]] = []
    for item in value:
        if not isinstance(item, dict):
            raise ValidatorError(f"override_installed_packages entries must be objects in {source_path}")
        records.append(
            {
                "package": _require_string(
                    item.get("package"),
                    field_name="override_installed_packages.package",
                    source_path=source_path,
                ),
                "version": _require_string(
                    item.get("version"),
                    field_name="override_installed_packages.version",
                    source_path=source_path,
                ),
                "architecture": _require_string(
                    item.get("architecture"),
                    field_name="override_installed_packages.architecture",
                    source_path=source_path,
                ),
                "filename": _require_string(
                    item.get("filename"),
                    field_name="override_installed_packages.filename",
                    source_path=source_path,
                ),
            }
        )
    return records


def validate_port_result_metadata(
    payload: dict[str, Any],
    *,
    apt_packages: list[str],
    source_path: Path,
) -> dict[str, Any]:
    port_repository = _require_string(payload.get("port_repository"), field_name="port_repository", source_path=source_path)
    port_tag_ref = _require_string(payload.get("port_tag_ref"), field_name="port_tag_ref", source_path=source_path)
    unavailable_reason = _require_optional_string(
        payload.get(PORT_UNAVAILABLE_FIELD),
        field_name=PORT_UNAVAILABLE_FIELD,
        source_path=source_path,
    )
    port_commit = _require_optional_string(payload.get("port_commit"), field_name="port_commit", source_path=source_path)
    port_release_tag = _require_optional_string(
        payload.get("port_release_tag"),
        field_name="port_release_tag",
        source_path=source_path,
    )
    if unavailable_reason is None:
        if port_commit is None or COMMIT_RE.fullmatch(port_commit) is None:
            raise ValidatorError(f"port_commit must be a 40-character lowercase hex commit in {source_path}")
        if port_release_tag is None or port_release_tag != f"build-{port_commit[:12]}":
            raise ValidatorError(f"port_release_tag must equal build-<commit[:12]> in {source_path}")
    elif port_commit is not None or port_release_tag is not None:
        raise ValidatorError(f"unavailable port results must not define commit or release tag in {source_path}")
    port_debs = _require_port_debs(
        payload.get("port_debs"),
        source_path=source_path,
        allow_empty=unavailable_reason is not None,
    )
    unported = _require_string_list(
        payload.get("unported_original_packages"),
        field_name="unported_original_packages",
        source_path=source_path,
    )
    installed = _require_override_installed_packages(
        payload.get("override_installed_packages"),
        source_path=source_path,
        allow_empty=unavailable_reason is not None,
    )
    ported_packages = [deb["package"] for deb in port_debs]
    if unavailable_reason is not None and ported_packages:
        raise ValidatorError(f"unavailable port results must not define port_debs in {source_path}")
    if set(ported_packages).intersection(unported):
        raise ValidatorError(f"port_debs and unported_original_packages must be disjoint in {source_path}")
    combined = [package for package in apt_packages if package in ported_packages or package in unported]
    if combined != apt_packages:
        raise ValidatorError(
            f"port_debs plus unported_original_packages must equal canonical apt_packages in {source_path}"
        )
    if ported_packages != [package for package in apt_packages if package in ported_packages]:
        raise ValidatorError(f"port_debs must follow canonical apt_packages order in {source_path}")
    installed_keys = [(item["package"], item["filename"], item["architecture"]) for item in installed]
    expected_keys = [(deb["package"], deb["filename"], deb["architecture"]) for deb in port_debs]
    if installed_keys != expected_keys:
        raise ValidatorError(f"override_installed_packages must align with port_debs in {source_path}")
    metadata: dict[str, Any] = {
        "port_repository": port_repository,
        "port_tag_ref": port_tag_ref,
        "port_commit": port_commit,
        "port_release_tag": port_release_tag,
        "port_debs": port_debs,
        "unported_original_packages": unported,
    }
    if unavailable_reason is not None:
        metadata[PORT_UNAVAILABLE_FIELD] = unavailable_reason
    return metadata


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


def load_result(
    path: Path,
    *,
    artifacts_root: Path,
    mode: str,
    require_casts: bool = False,
) -> dict[str, Any]:
    _validate_existing_artifact_file_path(
        path,
        field_name="result path",
        artifacts_root=artifacts_root,
        source_path=path,
    )
    payload = _load_json_object(path, description="result")
    missing = sorted(BASE_REQUIRED_RESULT_FIELDS - set(payload))
    if missing:
        raise ValidatorError(f"result schema mismatch in {path}: missing {', '.join(missing)}")
    if payload.get("schema_version") != 2:
        raise ValidatorError(f"schema_version must be 2 in {path}")
    library = _require_string(payload.get("library"), field_name="library", source_path=path)
    result_mode = _require_mode(payload.get("mode"), source_path=path)
    if result_mode != mode:
        raise ValidatorError(f"mode must be {mode} in {path}")
    required_fields = set(BASE_REQUIRED_RESULT_FIELDS)
    if mode == "port-04-test":
        required_fields.update(PORT_REQUIRED_RESULT_FIELDS)
        missing_port = sorted(PORT_REQUIRED_RESULT_FIELDS - set(payload))
        if missing_port:
            raise ValidatorError(f"port result schema mismatch in {path}: missing {', '.join(missing_port)}")
    optional_fields = set(OPTIONAL_RESULT_FIELDS)
    if mode == "port-04-test":
        optional_fields.add(PORT_UNAVAILABLE_FIELD)
    extras = sorted(set(payload) - required_fields - optional_fields)
    if extras:
        raise ValidatorError(f"unsupported result fields in {path}: {', '.join(extras)}")
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
    port_unavailable_reason = _require_optional_string(
        payload.get(PORT_UNAVAILABLE_FIELD),
        field_name=PORT_UNAVAILABLE_FIELD,
        source_path=path,
    )
    if mode == "original" and override_debs_installed:
        raise ValidatorError(f"override_debs_installed must be false for proof generation in {path}")
    if mode == "port-04-test" and port_unavailable_reason is None and not override_debs_installed:
        raise ValidatorError(f"override_debs_installed must be true for port proof generation in {path}")
    if mode == "port-04-test" and port_unavailable_reason is not None and override_debs_installed:
        raise ValidatorError(f"override_debs_installed must be false for unavailable port proof generation in {path}")
    if port_unavailable_reason is not None:
        if payload.get("status") != "failed":
            raise ValidatorError(f"unavailable port results must be failed in {path}")
        if payload.get("exit_code") == 0:
            raise ValidatorError(f"unavailable port results must have non-zero exit_code in {path}")
        if payload.get("cast_path") is not None:
            raise ValidatorError(f"unavailable port results must not define cast_path in {path}")
    if mode == "port-04-test":
        validate_port_result_metadata(payload, apt_packages=apt_packages, source_path=path)

    prefix = "" if mode == "original" else f"{mode}/"
    expected_result_path = f"{prefix}results/{library}/{testcase_id}.json"
    expected_log_path = f"{prefix}logs/{library}/{testcase_id}.log"
    expected_cast_path = f"{prefix}casts/{library}/{testcase_id}.cast"

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

    if require_casts and payload.get("cast_path") is None and port_unavailable_reason is None:
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
    mode: str,
    result_path: Path,
) -> None:
    expected = {
        "library": testcase_manifest.library,
        "mode": mode,
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
    mode: str,
) -> None:
    result_dir = artifact_root / "results" / testcase_manifest.library
    if mode != "original":
        result_dir = artifact_root / mode / "results" / testcase_manifest.library
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
        "mode": result["mode"],
        "client_application": testcase.client_application,
        "tags": list(testcase.tags),
        "requires": list(testcase.requires),
        "status": result["status"],
        "result_path": result["result_path"],
        "log_path": result["log_path"],
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
    mode: str = "original",
    libraries: list[str] | None = None,
    min_cases: int = 0,
    min_source_cases: int = 0,
    min_usage_cases: int = 0,
    require_casts: bool = False,
) -> dict[str, Any]:
    if mode not in VALID_MODES:
        raise ValidatorError("mode must be original or port-04-test")
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
        _validate_exact_result_set(artifact_root=artifact_root, testcase_manifest=testcase_manifest, mode=mode)

        case_rows: list[dict[str, Any]] = []
        port_library_metadata: dict[str, Any] | None = None
        for testcase in testcase_manifest.testcases:
            result_path = artifact_root / "results" / library / f"{testcase.id}.json"
            if mode != "original":
                result_path = artifact_root / mode / "results" / library / f"{testcase.id}.json"
            result = load_result(
                result_path,
                artifacts_root=artifact_root,
                mode=mode,
                require_casts=require_casts,
            )
            _validate_result_matches_testcase(
                result,
                testcase=testcase,
                testcase_manifest=testcase_manifest,
                mode=mode,
                result_path=result_path,
            )
            if mode == "port-04-test":
                metadata = validate_port_result_metadata(
                    result,
                    apt_packages=list(testcase_manifest.apt_packages),
                    source_path=result_path,
                )
                if port_library_metadata is None:
                    port_library_metadata = metadata
                elif port_library_metadata != metadata:
                    raise ValidatorError(f"inconsistent port provenance for {library}")
            case_rows.append(
                _case_proof(
                    result=result,
                    testcase=testcase,
                    artifact_root=artifact_root,
                    result_path=result_path,
                )
            )

        library_totals = _library_totals(case_rows)
        library_proof: dict[str, Any] = {
            "library": library,
            "apt_packages": list(testcase_manifest.apt_packages),
            "totals": library_totals,
        }
        if mode == "port-04-test":
            if port_library_metadata is None:
                raise ValidatorError(f"missing port provenance for {library}")
            library_proof.update(port_library_metadata)
        library_proof["testcases"] = case_rows
        proof_libraries.append(library_proof)
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
        "mode": mode,
        "suite": _suite_from_manifest(manifest),
        "totals": totals,
        "libraries": proof_libraries,
    }
