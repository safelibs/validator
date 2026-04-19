from __future__ import annotations

import json
import shutil
import subprocess
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from tools import ValidatorError, copy_file, ensure_parent, write_json


ALLOWED_REPORT_FORMATS = {
    "validator-wrapper-baseline",
    "imported-report-dir",
    "imported-json-results",
    "imported-matrix-tsv",
    "imported-log-marker",
}


@dataclass
class PreparedHarnessRun:
    repo_root: Path
    harness_script: Path
    dependents_path: Path
    downstream_dir: Path
    safe_deb_dir: Path | None
    artifact_root: Path


def _validate_library_name(library: str) -> str:
    if not library or library in {".", ".."}:
        raise ValidatorError(f"unsafe library name: {library!r}")
    if Path(library).is_absolute() or "/" in library or "\\" in library:
        raise ValidatorError(f"unsafe library name: {library!r}")
    return library


def _reset_dir(path: Path) -> None:
    if path.exists():
        stale = path.with_name(f"{path.name}.stale-{uuid.uuid4().hex}")
        path.rename(stale)
        shutil.rmtree(stale, ignore_errors=True)
    path.mkdir(parents=True, exist_ok=True)


def _copy_tree(source: Path, dest: Path) -> None:
    if source.is_dir():
        shutil.copytree(source, dest, symlinks=True)
        return
    copy_file(source, dest)


def _git(args: list[str], *, cwd: Path) -> None:
    try:
        completed = subprocess.run(
            ["git", *args],
            cwd=cwd,
            check=True,
            text=True,
            capture_output=True,
        )
    except OSError as exc:
        raise ValidatorError(f"git {' '.join(args)} failed in {cwd}: {type(exc).__name__}: {exc}") from exc
    except subprocess.CalledProcessError as exc:
        details = "\n".join(
            part.strip() for part in (exc.stdout or "", exc.stderr or "") if part.strip()
        )
        raise ValidatorError(
            f"git {' '.join(args)} failed in {cwd}: {details or f'exit {exc.returncode}'}"
        ) from exc
    if completed.returncode != 0:  # pragma: no cover - defensive fallback
        raise ValidatorError(f"git {' '.join(args)} failed in {cwd}: exit {completed.returncode}")


def materialize_scratch_repo(
    *,
    tests_root: Path,
    artifact_root: Path,
    library: str,
    mode: str,
    safe_deb_dir: Path | None,
) -> PreparedHarnessRun:
    library = _validate_library_name(library)
    if mode not in {"original", "safe"}:
        raise ValidatorError(f"unsupported harness mode for {library}: {mode}")

    tests_root = tests_root.resolve(strict=False)
    artifact_root = artifact_root.resolve(strict=False)
    library_root = tests_root / library
    tests_dir = library_root / "tests"
    harness_script = library_root / "host-run.sh"
    original_script = tests_dir / "harness-source" / "original-test-script.sh"
    safe_control = tests_dir / "harness-source" / "debian" / "control"
    dependents_source = tests_dir / "fixtures" / "dependents.json"
    baseline_script = tests_dir / "run.sh"
    tagged_port_root = tests_dir / "tagged-port"

    required_paths = {
        "host harness script": harness_script,
        "original harness script": original_script,
        "safe debian control": safe_control,
        "dependents fixture": dependents_source,
        "tagged-port root": tagged_port_root,
    }
    for label, path in required_paths.items():
        if not path.exists():
            raise ValidatorError(f"missing {label} for {library}: {path}")

    workspace_root = artifact_root / ".workspace" / "host-harness" / library / mode
    repo_root = workspace_root / "repo"
    downstream_dir = artifact_root / "downstream" / library / mode
    _reset_dir(workspace_root)
    _reset_dir(downstream_dir)
    repo_root.mkdir(parents=True, exist_ok=True)

    for child in sorted(tagged_port_root.iterdir(), key=lambda item: item.name):
        _copy_tree(child, repo_root / child.name)

    copy_file(original_script, repo_root / "test-original.sh")
    copy_file(safe_control, repo_root / "safe" / "debian" / "control")
    copy_file(dependents_source, repo_root / "dependents.json")
    if baseline_script.exists():
        copy_file(baseline_script, repo_root / "tests" / "run.sh")
    (repo_root / ".validator").mkdir(parents=True, exist_ok=True)

    staged_safe_deb_dir: Path | None = None
    if mode == "safe":
        if safe_deb_dir is None:
            raise ValidatorError(f"safe mode requires staged .deb files for {library}")
        deb_paths = sorted(safe_deb_dir.glob("*.deb"))
        if not deb_paths:
            raise ValidatorError(f"safe-deb leaf for {library} contains no .deb files: {safe_deb_dir}")
        staged_safe_deb_dir = repo_root / "safe" / "dist"
        staged_safe_deb_dir.mkdir(parents=True, exist_ok=True)
        for deb_path in deb_paths:
            copy_file(deb_path, staged_safe_deb_dir / deb_path.name)

    _git(["init"], cwd=repo_root)
    _git(["add", "-A"], cwd=repo_root)

    return PreparedHarnessRun(
        repo_root=repo_root,
        harness_script=harness_script,
        dependents_path=repo_root / "dependents.json",
        downstream_dir=downstream_dir,
        safe_deb_dir=staged_safe_deb_dir,
        artifact_root=artifact_root,
    )


def _require_string(value: Any, *, field: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValidatorError(f"{field} must be a non-empty string")
    return value


def _normalize_string_list(value: Any, *, field: str) -> list[str]:
    if not isinstance(value, list):
        raise ValidatorError(f"{field} must be a list")
    normalized: list[str] = []
    seen: set[str] = set()
    for item in value:
        text = _require_string(item, field=field)
        if text in seen:
            raise ValidatorError(f"{field} must not contain duplicates: {text}")
        normalized.append(text)
        seen.add(text)
    return normalized


def _summary_artifact_root(summary_path: Path) -> Path:
    if summary_path.name != "summary.json":
        raise ValidatorError(f"summary path must end in summary.json: {summary_path}")
    downstream_root = summary_path.parent.parent.parent
    if downstream_root.name != "downstream":
        raise ValidatorError(f"summary path must live under artifacts/downstream: {summary_path}")
    return downstream_root.parent


def _normalize_artifact_path(value: Any, *, artifact_root: Path) -> str:
    if isinstance(value, Path):
        candidate = value
    elif isinstance(value, str) and value.strip():
        candidate = Path(value)
    else:
        raise ValidatorError("summary artifacts values must be non-empty paths")

    artifact_root_abs = artifact_root.resolve(strict=False)
    if candidate.is_absolute():
        target = candidate.resolve(strict=False)
    else:
        target = (artifact_root / candidate).resolve(strict=False)

    try:
        relative = target.relative_to(artifact_root_abs)
    except ValueError as exc:
        raise ValidatorError(f"summary artifact path escapes artifact root: {candidate}") from exc
    return relative.as_posix()


def write_summary(*, summary_path: Path, payload: dict[str, Any]) -> None:
    if not isinstance(payload, dict):
        raise ValidatorError("summary payload must be a mapping")

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
        raise ValidatorError(f"unsupported summary fields: {', '.join(extras)}")

    artifact_root = _summary_artifact_root(summary_path)
    library = _require_string(payload.get("library"), field="library")
    mode = _require_string(payload.get("mode"), field="mode")
    if summary_path.parent.parent.name != library:
        raise ValidatorError(f"summary library does not match path: {library} vs {summary_path}")
    if summary_path.parent.name != mode:
        raise ValidatorError(f"summary mode does not match path: {mode} vs {summary_path}")

    summary_version = payload.get("summary_version")
    if summary_version != 1:
        raise ValidatorError("summary_version must be 1")

    status = _require_string(payload.get("status"), field="status")
    if status not in {"passed", "failed"}:
        raise ValidatorError("status must be passed or failed")

    report_format = _require_string(payload.get("report_format"), field="report_format")
    if report_format not in ALLOWED_REPORT_FORMATS:
        raise ValidatorError(
            "report_format must be one of: " + ", ".join(sorted(ALLOWED_REPORT_FORMATS))
        )

    expected_dependents = payload.get("expected_dependents")
    if not isinstance(expected_dependents, int) or expected_dependents < 0:
        raise ValidatorError("expected_dependents must be a non-negative integer")

    selected_dependents = _normalize_string_list(
        payload.get("selected_dependents"),
        field="selected_dependents",
    )
    passed_dependents = _normalize_string_list(payload.get("passed_dependents"), field="passed_dependents")
    failed_dependents = _normalize_string_list(payload.get("failed_dependents"), field="failed_dependents")
    warned_dependents = _normalize_string_list(payload.get("warned_dependents"), field="warned_dependents")
    skipped_dependents = _normalize_string_list(payload.get("skipped_dependents"), field="skipped_dependents")

    if selected_dependents and expected_dependents != len(selected_dependents):
        raise ValidatorError("expected_dependents must equal len(selected_dependents) after workload selection")

    selected_positions = {name: index for index, name in enumerate(selected_dependents)}
    for field_name, items in (
        ("passed_dependents", passed_dependents),
        ("failed_dependents", failed_dependents),
        ("warned_dependents", warned_dependents),
        ("skipped_dependents", skipped_dependents),
    ):
        positions: list[int] = []
        for item in items:
            if item not in selected_positions:
                raise ValidatorError(f"{field_name} item is not present in selected_dependents: {item}")
            positions.append(selected_positions[item])
        if positions != sorted(positions):
            raise ValidatorError(f"{field_name} must preserve selected_dependents order")

    all_terminal = passed_dependents + failed_dependents + warned_dependents + skipped_dependents
    if len(all_terminal) != len(set(all_terminal)):
        raise ValidatorError("terminal dependent buckets must be pairwise disjoint")
    if set(all_terminal) != set(selected_dependents):
        raise ValidatorError("terminal dependent buckets must cover selected_dependents exactly once")

    expected_status = "failed" if failed_dependents or warned_dependents or not selected_dependents and expected_dependents else "passed"
    if status != expected_status:
        raise ValidatorError(f"status must be {expected_status} for the provided dependent buckets")

    artifacts = payload.get("artifacts")
    if not isinstance(artifacts, dict):
        raise ValidatorError("artifacts must be a mapping")
    normalized_artifacts: dict[str, str] = {}
    for name, value in artifacts.items():
        key = _require_string(name, field="artifacts key")
        normalized_artifacts[key] = _normalize_artifact_path(value, artifact_root=artifact_root)

    normalized: dict[str, Any] = {
        "summary_version": 1,
        "library": library,
        "mode": mode,
        "status": status,
        "report_format": report_format,
        "expected_dependents": expected_dependents,
        "selected_dependents": selected_dependents,
        "passed_dependents": passed_dependents,
        "failed_dependents": failed_dependents,
        "warned_dependents": warned_dependents,
        "skipped_dependents": skipped_dependents,
        "artifacts": normalized_artifacts,
    }

    setup_stage_failure = not selected_dependents and expected_dependents > 0
    if "notes" in payload:
        notes = payload["notes"]
        if isinstance(notes, str):
            if not notes.strip():
                raise ValidatorError("notes must not be empty")
            normalized["notes"] = notes
        elif (
            isinstance(notes, list)
            and notes
            and all(isinstance(item, str) and item.strip() for item in notes)
        ):
            normalized["notes"] = list(notes)
        else:
            raise ValidatorError("notes must be a non-empty string or a list of non-empty strings")
    elif setup_stage_failure:
        raise ValidatorError("notes are required for setup-stage failures")

    ensure_parent(summary_path)
    write_json(summary_path, normalized)
