from __future__ import annotations

import json
import math
from pathlib import Path, PurePosixPath
from typing import Any

from tools import ValidatorError
from tools.host_harness import ALLOWED_REPORT_FORMATS
from tools.inventory import validator_execution_strategy_for


RESULT_MODES = ("original", "safe")
SUMMARY_BUCKETS = (
    "passed_dependents",
    "failed_dependents",
    "warned_dependents",
    "skipped_dependents",
)
REQUIRED_RESULT_FIELDS = {
    "library",
    "mode",
    "execution_strategy",
    "status",
    "started_at",
    "finished_at",
    "duration_seconds",
    "log_path",
    "cast_path",
    "exit_code",
}
PROOF_SUMMARY_FIELDS = (
    "report_format",
    "expected_dependents",
    "selected_dependents",
    "passed_dependents",
    "failed_dependents",
    "warned_dependents",
    "skipped_dependents",
)


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


def _reject_json_constant(value: str) -> None:
    raise ValueError(f"invalid JSON constant: {value}")


def _artifact_root_relative(path: Path, *, artifacts_root: Path, source_path: Path) -> str:
    try:
        return path.resolve(strict=False).relative_to(
            artifacts_root.resolve(strict=False)
        ).as_posix()
    except ValueError as exc:
        raise ValidatorError(f"path is outside artifact root in {source_path}: {path}") from exc


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


def _result_path_identity(path: Path, *, artifacts_root: Path) -> tuple[str, str] | None:
    absolute_path = path if path.is_absolute() else Path.cwd() / path
    try:
        relative = absolute_path.relative_to(artifacts_root.resolve(strict=False) / "results")
    except ValueError:
        return None
    if len(relative.parts) != 2 or relative.suffix != ".json":
        return None
    return relative.parts[0], relative.stem


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

    status = _require_string(payload.get("status"), field_name="status", source_path=path)
    if status not in {"passed", "failed"}:
        raise ValidatorError(f"status must be passed or failed in {path}")
    _require_string(payload.get("library"), field_name="library", source_path=path)
    _require_string(payload.get("mode"), field_name="mode", source_path=path)
    _require_string(
        payload.get("execution_strategy"),
        field_name="execution_strategy",
        source_path=path,
    )
    _require_string(payload.get("started_at"), field_name="started_at", source_path=path)
    _require_string(payload.get("finished_at"), field_name="finished_at", source_path=path)
    _require_nonnegative_number(
        payload.get("duration_seconds"),
        field_name="duration_seconds",
        source_path=path,
    )
    _require_int(payload.get("exit_code"), field_name="exit_code", source_path=path)

    if payload.get("log_path") is None:
        raise ValidatorError(f"log_path must be non-null in {path}")
    log_target = validate_artifact_relative_path(
        payload.get("log_path"),
        field_name="log_path",
        artifacts_root=artifacts_root,
        source_path=path,
    )
    validate_artifact_relative_path(
        payload.get("cast_path"),
        field_name="cast_path",
        artifacts_root=artifacts_root,
        source_path=path,
    )
    if "downstream_summary_path" in payload:
        validate_artifact_relative_path(
            payload.get("downstream_summary_path"),
            field_name="downstream_summary_path",
            artifacts_root=artifacts_root,
            source_path=path,
        )

    identity = _result_path_identity(path, artifacts_root=artifacts_root)
    if identity is not None:
        library, mode = identity
        expected_log_path = f"logs/{library}/{mode}.log"
        if payload.get("log_path") != expected_log_path:
            raise ValidatorError(
                f"log_path must equal {expected_log_path!r} for result path {path}"
            )
        assert log_target is not None
        if not log_target.is_file():
            raise ValidatorError(f"log_path does not exist for result path {path}: {log_target}")

    return payload


def _summary_path_identity(path: Path, *, artifacts_root: Path) -> tuple[str, str] | None:
    absolute_path = path if path.is_absolute() else Path.cwd() / path
    try:
        relative = absolute_path.relative_to(artifacts_root.resolve(strict=False) / "downstream")
    except ValueError:
        return None
    if len(relative.parts) != 3 or relative.parts[2] != "summary.json":
        return None
    return relative.parts[0], relative.parts[1]


def _normalize_string_list(value: Any, *, field_name: str, source_path: Path) -> list[str]:
    if not isinstance(value, list):
        raise ValidatorError(f"{field_name} must be a list in {source_path}")
    normalized: list[str] = []
    seen: set[str] = set()
    for item in value:
        text = _require_string(item, field_name=field_name, source_path=source_path)
        if text in seen:
            raise ValidatorError(f"{field_name} must not contain duplicates in {source_path}: {text}")
        normalized.append(text)
        seen.add(text)
    return normalized


def _normalize_summary_artifacts(
    value: Any,
    *,
    artifacts_root: Path,
    source_path: Path,
) -> dict[str, str]:
    if not isinstance(value, dict):
        raise ValidatorError(f"artifacts must be a mapping in {source_path}")
    normalized: dict[str, str] = {}
    for name, artifact_path in value.items():
        key = _require_string(name, field_name="artifacts key", source_path=source_path)
        target = validate_artifact_relative_path(
            str(artifact_path) if isinstance(artifact_path, Path) else artifact_path,
            field_name=f"artifacts.{key}",
            artifacts_root=artifacts_root,
            source_path=source_path,
        )
        assert target is not None
        normalized[key] = _artifact_root_relative(
            target,
            artifacts_root=artifacts_root,
            source_path=source_path,
        )
    return normalized


def _normalize_notes(value: Any, *, source_path: Path) -> str | list[str]:
    if isinstance(value, str) and value.strip():
        return value
    if isinstance(value, list) and value and all(isinstance(item, str) and item.strip() for item in value):
        return list(value)
    raise ValidatorError(f"notes must be a non-empty string or list of non-empty strings in {source_path}")


def load_downstream_summary(path: Path, *, artifacts_root: Path) -> dict[str, Any]:
    _validate_existing_artifact_file_path(
        path,
        field_name="downstream summary path",
        artifacts_root=artifacts_root,
        source_path=path,
    )
    payload = _load_json_object(path, description="downstream summary")

    allowed_keys = {
        "summary_version",
        "library",
        "mode",
        "status",
        "report_format",
        "expected_dependents",
        "selected_dependents",
        "passed_dependents",
        "failed_dependents",
        "warned_dependents",
        "skipped_dependents",
        "artifacts",
        "notes",
    }
    extras = sorted(set(payload) - allowed_keys)
    if extras:
        raise ValidatorError(f"unsupported summary fields in {path}: {', '.join(extras)}")

    if payload.get("summary_version") != 1:
        raise ValidatorError(f"summary_version must be 1 in {path}")

    library = _require_string(payload.get("library"), field_name="library", source_path=path)
    mode = _require_string(payload.get("mode"), field_name="mode", source_path=path)
    identity = _summary_path_identity(path, artifacts_root=artifacts_root)
    if identity is not None and identity != (library, mode):
        raise ValidatorError(f"summary identity does not match path in {path}")

    status = _require_string(payload.get("status"), field_name="status", source_path=path)
    if status not in {"passed", "failed"}:
        raise ValidatorError(f"status must be passed or failed in {path}")

    report_format = _require_string(
        payload.get("report_format"),
        field_name="report_format",
        source_path=path,
    )
    if report_format not in ALLOWED_REPORT_FORMATS:
        raise ValidatorError(
            "report_format must be one of "
            + ", ".join(sorted(ALLOWED_REPORT_FORMATS))
            + f" in {path}"
        )

    expected_dependents = payload.get("expected_dependents")
    if isinstance(expected_dependents, bool) or not isinstance(expected_dependents, int) or expected_dependents < 0:
        raise ValidatorError(f"expected_dependents must be a non-negative integer in {path}")

    selected_dependents = _normalize_string_list(
        payload.get("selected_dependents"),
        field_name="selected_dependents",
        source_path=path,
    )
    terminal_buckets = {
        field_name: _normalize_string_list(payload.get(field_name), field_name=field_name, source_path=path)
        for field_name in SUMMARY_BUCKETS
    }

    if selected_dependents and expected_dependents != len(selected_dependents):
        raise ValidatorError(
            f"expected_dependents must equal len(selected_dependents) after workload selection in {path}"
        )

    selected_positions = {name: index for index, name in enumerate(selected_dependents)}
    for field_name, items in terminal_buckets.items():
        positions: list[int] = []
        for item in items:
            if item not in selected_positions:
                raise ValidatorError(f"{field_name} item is not present in selected_dependents in {path}: {item}")
            positions.append(selected_positions[item])
        if positions != sorted(positions):
            raise ValidatorError(f"{field_name} must preserve selected_dependents order in {path}")

    all_terminal = [
        item
        for field_name in SUMMARY_BUCKETS
        for item in terminal_buckets[field_name]
    ]
    if len(all_terminal) != len(set(all_terminal)):
        raise ValidatorError(f"terminal dependent buckets must be pairwise disjoint in {path}")
    if set(all_terminal) != set(selected_dependents):
        raise ValidatorError(f"terminal dependent buckets must cover selected_dependents exactly once in {path}")

    expected_status = (
        "failed"
        if terminal_buckets["failed_dependents"]
        or terminal_buckets["warned_dependents"]
        or (not selected_dependents and expected_dependents)
        else "passed"
    )
    if status != expected_status:
        raise ValidatorError(f"status must be {expected_status} for the provided dependent buckets in {path}")

    setup_stage_failure = not selected_dependents and expected_dependents > 0
    notes = payload.get("notes")
    normalized: dict[str, Any] = {
        "summary_version": 1,
        "library": library,
        "mode": mode,
        "status": status,
        "report_format": report_format,
        "expected_dependents": expected_dependents,
        "selected_dependents": selected_dependents,
        **terminal_buckets,
        "artifacts": _normalize_summary_artifacts(
            payload.get("artifacts"),
            artifacts_root=artifacts_root,
            source_path=path,
        ),
    }
    if notes is not None:
        normalized["notes"] = _normalize_notes(notes, source_path=path)
    elif setup_stage_failure:
        raise ValidatorError(f"notes are required for setup-stage failures in {path}")
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


def _proof_summary(summary: dict[str, Any]) -> dict[str, Any]:
    return {field_name: summary[field_name] for field_name in PROOF_SUMMARY_FIELDS}


def _validate_proof_counted_summary(summary: dict[str, Any], *, summary_path: Path) -> None:
    selected_dependents = summary["selected_dependents"]
    expected_dependents = summary["expected_dependents"]
    if expected_dependents != len(selected_dependents):
        raise ValidatorError(
            f"expected_dependents must equal len(selected_dependents) for proof coverage in {summary_path}"
        )
    if expected_dependents <= 0:
        raise ValidatorError(f"expected_dependents must be greater than zero for proof coverage in {summary_path}")
    if not selected_dependents:
        raise ValidatorError(f"setup-stage failures do not count as proof coverage in {summary_path}")


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


def build_proof(
    manifest: dict[str, Any],
    *,
    artifact_root: Path,
    libraries: list[str] | None = None,
    excluded_libraries: dict[str, str] | None = None,
    min_safe_workloads: int = 0,
    min_total_workloads: int = 0,
) -> dict[str, Any]:
    if min_safe_workloads < 0 or min_total_workloads < 0:
        raise ValidatorError("workload thresholds must be non-negative")

    selected_entries = _selected_manifest_entries(manifest, libraries=libraries)
    selected_names = [str(entry["name"]) for entry in selected_entries]
    normalized_exclusions = _normalize_exclusions(
        excluded_libraries,
        selected_names=selected_names,
    )
    excluded_set = {entry["library"] for entry in normalized_exclusions}
    included_entries = [entry for entry in selected_entries if str(entry["name"]) not in excluded_set]
    included_names = [str(entry["name"]) for entry in included_entries]

    proof_libraries: list[dict[str, Any]] = []
    safe_workloads = 0
    total_workloads = 0
    report_formats: set[str] = set()

    artifact_root = artifact_root.resolve(strict=False)
    for entry in included_entries:
        library = str(entry["name"])
        execution_strategy = validator_execution_strategy_for(entry)
        library_proof: dict[str, Any] = {"library": library}

        for mode in RESULT_MODES:
            result_path = artifact_root / "results" / library / f"{mode}.json"
            if not result_path.is_file():
                raise ValidatorError(f"missing result JSON for {library}/{mode}: {result_path}")
            result = load_result(result_path, artifacts_root=artifact_root)
            _require_result_field(result, field_name="library", expected_value=library, result_path=result_path)
            _require_result_field(result, field_name="mode", expected_value=mode, result_path=result_path)
            _require_result_field(
                result,
                field_name="execution_strategy",
                expected_value=execution_strategy,
                result_path=result_path,
            )

            expected_log_path = f"logs/{library}/{mode}.log"
            _require_result_field(
                result,
                field_name="log_path",
                expected_value=expected_log_path,
                result_path=result_path,
            )
            log_target = validate_artifact_relative_path(
                result["log_path"],
                field_name="log_path",
                artifacts_root=artifact_root,
                source_path=result_path,
            )
            assert log_target is not None
            if not log_target.is_file():
                raise ValidatorError(f"missing log referenced by {result_path}: {log_target}")

            if mode == "original":
                if result.get("cast_path") is not None:
                    raise ValidatorError(f"original result cast_path must be null for {library}")
            else:
                expected_cast_path = f"casts/{library}/safe.cast"
                _require_result_field(
                    result,
                    field_name="cast_path",
                    expected_value=expected_cast_path,
                    result_path=result_path,
                )
                cast_target = validate_artifact_relative_path(
                    result["cast_path"],
                    field_name="cast_path",
                    artifacts_root=artifact_root,
                    source_path=result_path,
                )
                assert cast_target is not None
                if not cast_target.is_file():
                    raise ValidatorError(f"missing safe cast referenced by {result_path}: {cast_target}")
                cast_info = inspect_cast(cast_target)

            expected_summary_path = f"downstream/{library}/{mode}/summary.json"
            if "downstream_summary_path" not in result:
                raise ValidatorError(f"downstream_summary_path is required for proof-counted result {result_path}")
            _require_result_field(
                result,
                field_name="downstream_summary_path",
                expected_value=expected_summary_path,
                result_path=result_path,
            )
            summary_target = validate_artifact_relative_path(
                result["downstream_summary_path"],
                field_name="downstream_summary_path",
                artifacts_root=artifact_root,
                source_path=result_path,
            )
            assert summary_target is not None
            if not summary_target.is_file():
                raise ValidatorError(f"missing downstream summary referenced by {result_path}: {summary_target}")
            summary_source = artifact_root / "downstream" / library / mode / "summary.json"
            summary = load_downstream_summary(summary_source, artifacts_root=artifact_root)
            _require_result_field(summary, field_name="library", expected_value=library, result_path=summary_target)
            _require_result_field(summary, field_name="mode", expected_value=mode, result_path=summary_target)
            if result["status"] != summary["status"]:
                raise ValidatorError(
                    f"result status must match downstream summary status for {library}/{mode}"
                )
            _validate_proof_counted_summary(summary, summary_path=summary_target)

            report_formats.add(summary["report_format"])
            total_workloads += summary["expected_dependents"]
            if mode == "safe":
                safe_workloads += summary["expected_dependents"]

            mode_proof: dict[str, Any] = {
                "result_path": f"results/{library}/{mode}.json",
                "status": result["status"],
                "summary_path": expected_summary_path,
            }
            if mode == "safe":
                mode_proof.update(
                    {
                        "cast_path": f"casts/{library}/safe.cast",
                        **cast_info,
                    }
                )
            mode_proof["summary"] = _proof_summary(summary)
            library_proof[mode] = mode_proof

        proof_libraries.append(library_proof)

    if min_safe_workloads and safe_workloads < min_safe_workloads:
        raise ValidatorError(
            f"safe workload threshold not met: {safe_workloads} < {min_safe_workloads}"
        )
    if min_total_workloads and total_workloads < min_total_workloads:
        raise ValidatorError(
            f"total workload threshold not met: {total_workloads} < {min_total_workloads}"
        )

    return {
        "proof_version": 1,
        "included_libraries": included_names,
        "excluded_libraries": normalized_exclusions,
        "totals": {
            "included_libraries": len(included_names),
            "excluded_libraries": len(normalized_exclusions),
            "result_runs": len(included_names) * 2,
            "safe_casts": len(included_names),
            "safe_workloads": safe_workloads,
            "total_workloads": total_workloads,
            "report_formats": sorted(report_formats),
        },
        "libraries": proof_libraries,
    }
