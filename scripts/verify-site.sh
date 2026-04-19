#!/usr/bin/env bash
set -euo pipefail

config=
results_root=
site_root=
artifacts_root=
proof_path=
tests_root=

while (($# > 0)); do
  case "$1" in
    --config)
      config=$2
      shift 2
      ;;
    --results-root)
      results_root=$2
      shift 2
      ;;
    --artifacts-root)
      artifacts_root=$2
      shift 2
      ;;
    --proof-path)
      proof_path=$2
      shift 2
      ;;
    --site-root)
      site_root=$2
      shift 2
      ;;
    --tests-root)
      tests_root=$2
      shift 2
      ;;
    *)
      echo "unexpected argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$config" || -z "$results_root" || -z "$site_root" ]]; then
  echo "usage: verify-site.sh --config <manifest> --results-root <dir> [--artifacts-root <dir>] [--proof-path <path>] [--tests-root <dir>] --site-root <dir>" >&2
  exit 1
fi

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

python3 - "$repo_root" "$config" "$results_root" "$site_root" "$artifacts_root" "$proof_path" "$tests_root" <<'PY'
from __future__ import annotations

import json
import re
import sys
import html
from pathlib import Path

repo_root = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(repo_root))

from tools import ValidatorError
from tools.inventory import load_manifest
from tools import proof as proof_tools
from tools import render_site


def fail(message: str) -> None:
    raise SystemExit(message)


def validator_call(description: str, func, *args, **kwargs):
    try:
        return func(*args, **kwargs)
    except ValidatorError as exc:
        fail(f"{description}: {exc}")


config_path = Path(sys.argv[2])
results_root = Path(sys.argv[3])
site_root = Path(sys.argv[4])
artifacts_root_arg = sys.argv[5]
proof_path_arg = sys.argv[6]
tests_root_arg = sys.argv[7]
artifacts_root = Path(artifacts_root_arg) if artifacts_root_arg else results_root.parent
tests_root = Path(tests_root_arg) if tests_root_arg else repo_root / "tests"
artifacts_root_resolved = artifacts_root.resolve()
proof_path = Path(proof_path_arg) if proof_path_arg else artifacts_root / "proof" / "validator-proof.json"
proof_path_resolved = proof_path.resolve(strict=False)
try:
    proof_path_resolved.relative_to(artifacts_root_resolved)
except ValueError:
    fail(f"proof path must resolve inside the artifact root: {proof_path}")

manifest = validator_call("load manifest", load_manifest, config_path)
manifest_libraries = [str(entry["name"]) for entry in manifest["libraries"]]
manifest_set = set(manifest_libraries)


def validate_relative_artifact_path(value: str | None, *, field_name: str, source: str) -> Path | None:
    return validator_call(
        "validate artifact path",
        proof_tools.validate_artifact_relative_path,
        value,
        field_name=field_name,
        artifacts_root=artifacts_root,
        source_path=Path(source),
    )


def resolve_site_href(value: str | None, *, field_name: str, source: str) -> Path | None:
    if value is None:
        return None
    href_target = (site_root / value).resolve(strict=False)
    try:
        href_target.relative_to(artifacts_root_resolved)
    except ValueError:
        fail(f"{field_name} must resolve within the artifact root in {source}")
    return href_target


try:
    proof_file = json.loads(proof_path.read_text())
except FileNotFoundError:
    fail(f"missing proof manifest: {proof_path}")
except json.JSONDecodeError as exc:
    fail(f"invalid proof manifest JSON at {proof_path}: {exc}")
if not isinstance(proof_file, dict):
    fail(f"proof manifest must be a JSON object: {proof_path}")

included_libraries = proof_file.get("included_libraries")
if not isinstance(included_libraries, list) or not all(isinstance(item, str) for item in included_libraries):
    fail("proof included_libraries must be a list of strings")
if len(included_libraries) != len(set(included_libraries)):
    fail("proof included_libraries must not contain duplicates")
if any(library not in manifest_set for library in included_libraries):
    fail("proof included_libraries contains unknown libraries")

excluded_entries = proof_file.get("excluded_libraries")
if not isinstance(excluded_entries, list):
    fail("proof excluded_libraries must be a list")
excluded_note_map: dict[str, str] = {}
for entry in excluded_entries:
    if not isinstance(entry, dict) or set(entry) != {"library", "note"}:
        fail(f"malformed excluded library entry: {entry!r}")
    library = entry["library"]
    note = entry["note"]
    if not isinstance(library, str) or not library:
        fail(f"malformed excluded library entry: {entry!r}")
    if not isinstance(note, str) or not note.strip():
        fail(f"excluded library note must be non-empty: {entry!r}")
    if library in excluded_note_map:
        fail(f"duplicate excluded library entry: {library}")
    if library not in manifest_set:
        fail(f"excluded library is not in manifest: {library}")
    excluded_note_map[library] = note

selected_set = set(included_libraries) | set(excluded_note_map)
selected_libraries = [library for library in manifest_libraries if library in selected_set]
if set(selected_libraries) != selected_set:
    fail("proof selected library set does not match manifest")
proof_kwargs = {
    "artifact_root": artifacts_root,
    "libraries": selected_libraries,
    "excluded_libraries": excluded_note_map,
}
if proof_file.get("proof_version") == 2:
    proof_kwargs["tests_root"] = tests_root
expected_proof = validator_call(
    "rebuild proof",
    proof_tools.build_proof,
    manifest,
    **proof_kwargs,
)
if expected_proof != proof_file:
    fail("proof manifest does not match rebuilt proof")

site_data_path = site_root / "site-data.json"
if not site_data_path.is_file():
    fail(f"missing site-data.json: {site_data_path}")

site_data = json.loads(site_data_path.read_text())
if not isinstance(site_data, dict):
    fail(f"site-data.json must be a JSON object: {site_data_path}")
if set(site_data) != {"results", "proof"}:
    fail(f"site-data.json must define exactly results and proof: {site_data_path}")

site_rows = site_data.get("results")
if not isinstance(site_rows, list):
    fail(f"site-data.json must define a results list: {site_data_path}")
site_proof = site_data.get("proof")
if not isinstance(site_proof, dict):
    fail(f"site-data.json must define a proof object: {site_data_path}")

expected_site_proof = validator_call(
    "load proof for site",
    render_site.load_proof,
    proof_path,
    artifacts_root=artifacts_root,
    output_root=site_root,
)
if site_proof != expected_site_proof:
    fail("site-data.json proof does not match proof manifest plus deterministic cast_href fields")

all_results = validator_call(
    "load rendered results",
    render_site.load_results,
    results_root,
    artifacts_root=artifacts_root,
)
for result in all_results:
    if str(result["library"]) not in manifest_set:
        fail(f"unexpected library in results: {result['library']}")
filtered_results = [
    result
    for result in all_results
    if str(result["library"]) in set(included_libraries)
]
if proof_file.get("proof_version") == 2:
    expected_keys = {
        (str(library_entry["library"]), str(case["testcase_id"]))
        for library_entry in proof_file.get("libraries", [])
        if isinstance(library_entry, dict)
        for case in library_entry.get("cases", [])
        if isinstance(case, dict)
    }
    actual_keys = {
        (str(result["library"]), str(result.get("testcase_id") or ""))
        for result in filtered_results
    }
    if actual_keys != expected_keys:
        fail(f"filtered result rows must cover proof cases exactly: expected {sorted(expected_keys)}, found {sorted(actual_keys)}")
else:
    expected_keys = {(library, mode) for library in included_libraries for mode in ("original", "safe")}
    actual_keys = {(str(result["library"]), str(result["mode"])) for result in filtered_results}
    if actual_keys != expected_keys:
        fail(f"filtered result rows must cover proof included libraries exactly: expected {sorted(expected_keys)}, found {sorted(actual_keys)}")
expected_rows = render_site.build_site_rows(
    sorted(filtered_results, key=render_site.result_sort_key),
    output_root=site_root,
    artifacts_root=artifacts_root,
)

normalize = lambda rows: sorted(
    [
        {
            "library": row["library"],
            "mode": row["mode"],
            "testcase_id": row.get("testcase_id"),
            "apt_packages": row.get("apt_packages"),
            "status": row["status"],
            "log_path": row["log_path"],
            "cast_path": row["cast_path"],
            "log_href": row["log_href"],
            "cast_href": row["cast_href"],
        }
        for row in rows
    ],
    key=lambda row: (row["library"], row["mode"]),
)

if normalize(site_rows) != normalize(expected_rows):
    fail("site-data.json results do not match the proof-filtered result JSON set exactly")

excluded_set = set(excluded_note_map)
excluded_result_rows = [row for row in site_rows if row["library"] in excluded_set]
if excluded_result_rows:
    fail(f"site-data.json results must not include excluded libraries: {excluded_result_rows}")

for row in site_rows:
    log_href = row.get("log_href")
    if not log_href:
        fail(f"missing log_href in site row: {row}")
    log_target = validate_relative_artifact_path(
        row["log_path"],
        field_name="log_path",
        source=f"site-data row {row['library']}/{row['mode']}",
    )
    assert log_target is not None
    resolved_log_href = resolve_site_href(
        log_href,
        field_name="log_href",
        source=f"site-data row {row['library']}/{row['mode']}",
    )
    assert resolved_log_href is not None
    if resolved_log_href != log_target:
        fail(f"log_href does not match log_path in site row: {row}")
    if not resolved_log_href.is_file():
        fail(f"missing log target referenced by site: {log_href}")
    cast_href = row.get("cast_href")
    if row["cast_path"] is None:
        if cast_href is not None:
            fail(f"unexpected cast_href for non-cast row: {row}")
    else:
        if not cast_href:
            fail(f"missing cast_href for cast row: {row}")
        cast_target = validate_relative_artifact_path(
            row["cast_path"],
            field_name="cast_path",
            source=f"site-data row {row['library']}/{row['mode']}",
        )
        assert cast_target is not None
        resolved_cast_href = resolve_site_href(
            cast_href,
            field_name="cast_href",
            source=f"site-data row {row['library']}/{row['mode']}",
        )
        assert resolved_cast_href is not None
        if resolved_cast_href != cast_target:
            fail(f"cast_href does not match cast_path in site row: {row}")
        if not resolved_cast_href.is_file():
            fail(f"missing cast target referenced by site: {cast_href}")

if site_proof.get("proof_version") == 2:
    for library_entry in site_proof["libraries"]:
        for case_entry in library_entry.get("cases", []):
            cast_path = case_entry.get("cast_path")
            if cast_path is None:
                continue
            cast_href = case_entry.get("cast_href")
            if not cast_href:
                fail(f"missing proof cast_href for {library_entry['library']}/{case_entry.get('testcase_id')}")
            cast_target = validate_relative_artifact_path(
                cast_path,
                field_name="cast_path",
                source=f"proof row {library_entry['library']}/{case_entry.get('testcase_id')}",
            )
            assert cast_target is not None
            resolved_cast_href = resolve_site_href(
                cast_href,
                field_name="proof cast_href",
                source=f"proof row {library_entry['library']}/{case_entry.get('testcase_id')}",
            )
            assert resolved_cast_href is not None
            if resolved_cast_href != cast_target:
                fail(f"proof cast_href does not match cast_path for {library_entry['library']}/{case_entry.get('testcase_id')}")
else:
    for library_entry in site_proof["libraries"]:
        safe_entry = library_entry["safe"]
        cast_path = safe_entry["cast_path"]
        cast_href = safe_entry.get("cast_href")
        if not cast_href:
            fail(f"missing proof cast_href for {library_entry['library']}")
        cast_target = validate_relative_artifact_path(
            cast_path,
            field_name="cast_path",
            source=f"proof row {library_entry['library']}",
        )
        assert cast_target is not None
        resolved_cast_href = resolve_site_href(
            cast_href,
            field_name="proof cast_href",
            source=f"proof row {library_entry['library']}",
        )
        assert resolved_cast_href is not None
        if resolved_cast_href != cast_target:
            fail(f"proof cast_href does not match cast_path for {library_entry['library']}")

index_path = site_root / "index.html"
if not index_path.is_file():
    fail(f"missing rendered index.html: {index_path}")

html_text = index_path.read_text()
html_rows = set(re.findall(r'data-library="([^"]+)" data-mode="([^"]+)"', html_text))
expected_html_rows = {(row["library"], row["mode"]) for row in expected_rows}
if html_rows != expected_html_rows:
    fail(f"site index rows mismatch: expected {sorted(expected_html_rows)}, found {sorted(html_rows)}")

proof_totals = site_proof.get("totals")
if not isinstance(proof_totals, dict):
    fail("site-data.json proof totals must be an object")
if site_proof.get("proof_version") == 2:
    numeric_total_fields = (
        "included_libraries",
        "excluded_libraries",
        "cases",
        "passed",
        "failed",
        "casts",
    )
else:
    numeric_total_fields = (
        "included_libraries",
        "excluded_libraries",
        "result_runs",
        "safe_casts",
        "safe_workloads",
        "total_workloads",
    )
for field_name in numeric_total_fields:
    marker = f'data-proof-total="{field_name}"'
    if marker not in html_text:
        fail(f"missing proof total marker in index.html: {marker}")
    escaped_value = html.escape(str(proof_totals.get(field_name)))
    value_pattern = rf'{re.escape(marker)}[^>]*><strong>{re.escape(escaped_value)}</strong>'
    if re.search(value_pattern, html_text) is None:
        fail(f"missing proof total value in index.html for {field_name}: {escaped_value}")

if site_proof.get("proof_version") != 2:
    format_marker = 'data-proof-total="report_formats"'
    if format_marker not in html_text:
        fail(f"missing proof total marker in index.html: {format_marker}")
    report_formats = proof_totals.get("report_formats")
    if not isinstance(report_formats, list):
        fail("proof report_formats total must be a list")
    for report_format in report_formats:
        escaped_format = html.escape(str(report_format))
        if escaped_format not in html_text:
            fail(f"missing proof report format in index.html: {escaped_format}")

for library in included_libraries:
    marker = f'data-proof-library="{library}"'
    if marker not in html_text:
        fail(f"missing proof row marker in index.html: {marker}")

for library in excluded_note_map:
    marker = f'data-proof-excluded-library="{library}"'
    if marker not in html_text:
        fail(f"missing proof exclusion marker in index.html: {marker}")
PY
