#!/usr/bin/env bash
set -euo pipefail

config=
tests_root=
artifacts_root=
proof_path=
site_root=
libraries=()

while (($# > 0)); do
  case "$1" in
    --config)
      config=${2:-}
      shift 2
      ;;
    --tests-root)
      tests_root=${2:-}
      shift 2
      ;;
    --artifacts-root)
      artifacts_root=${2:-}
      shift 2
      ;;
    --proof-path)
      proof_path=${2:-}
      shift 2
      ;;
    --site-root)
      site_root=${2:-}
      shift 2
      ;;
    --library)
      libraries+=("${2:-}")
      shift 2
      ;;
    *)
      echo "unexpected argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$config" || -z "$tests_root" || -z "$artifacts_root" || -z "$proof_path" || -z "$site_root" ]]; then
  echo "usage: verify-site.sh --config <repositories.yml> --tests-root <tests-dir> --artifacts-root <artifacts-dir> --proof-path <proof-json> --site-root <site-dir> [--library <name> ...]" >&2
  exit 1
fi

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

python3 - "$repo_root" "$config" "$tests_root" "$artifacts_root" "$proof_path" "$site_root" "${libraries[@]}" <<'PY'
from __future__ import annotations

import html
import json
import re
import sys
from pathlib import Path
from typing import Any

repo_root = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(repo_root))

from tools import ValidatorError
from tools.inventory import load_manifest
from tools import proof as proof_tools
from tools import render_site
from tools.testcases import load_manifests


def fail(message: str) -> None:
    raise SystemExit(message)


def validator_call(description: str, func, *args, **kwargs):
    try:
        return func(*args, **kwargs)
    except ValidatorError as exc:
        fail(f"{description}: {exc}")


def reject_duplicates(values: list[str], *, field_name: str) -> None:
    duplicates = sorted({value for value in values if values.count(value) > 1})
    if duplicates:
        fail(f"{field_name} must not contain duplicates: {', '.join(duplicates)}")


def load_json_object(path: Path, *, description: str) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text())
    except FileNotFoundError:
        fail(f"missing {description}: {path}")
    except json.JSONDecodeError as exc:
        fail(f"invalid {description} JSON at {path}: {exc}")
    if not isinstance(payload, dict):
        fail(f"{description} must be a JSON object: {path}")
    return payload


def resolve_inside(root: Path, value: str | None, *, field_name: str, source: str) -> Path:
    if not isinstance(value, str) or not value:
        fail(f"{field_name} must be a non-empty string in {source}")
    if "\\" in value:
        fail(f"{field_name} must use forward slashes in {source}")
    target = (root / value).resolve(strict=False)
    try:
        target.relative_to(root.resolve(strict=False))
    except ValueError:
        fail(f"{field_name} must resolve inside {root} in {source}: {value}")
    return target


def artifact_source(value: str | None, *, field_name: str, source: str, artifacts_root: Path) -> Path:
    target = validator_call(
        "validate artifact path",
        proof_tools.validate_artifact_relative_path,
        value,
        field_name=field_name,
        artifacts_root=artifacts_root,
        source_path=Path(source),
    )
    if target is None:
        fail(f"{field_name} must be non-null in {source}")
    if not target.is_file():
        fail(f"{field_name} source file does not exist in {source}: {value}")
    return target


config_path = Path(sys.argv[2])
tests_root = Path(sys.argv[3])
artifacts_root = Path(sys.argv[4]).resolve(strict=False)
proof_path = Path(sys.argv[5])
site_root = Path(sys.argv[6]).resolve(strict=False)
cli_libraries = sys.argv[7:]

proof_path_resolved = proof_path.resolve(strict=False)
try:
    proof_path_resolved.relative_to(artifacts_root)
except ValueError:
    fail(f"proof path must resolve inside the artifact root: {proof_path}")

manifest = validator_call("load manifest", load_manifest, config_path)
validator_call("load testcase manifests", load_manifests, manifest, tests_root=tests_root)
manifest_libraries = [str(entry["name"]) for entry in manifest["libraries"]]
manifest_set = set(manifest_libraries)
reject_duplicates(manifest_libraries, field_name="repositories.yml libraries")

proof_file = load_json_object(proof_path, description="proof manifest")
if proof_file.get("proof_version") != 2:
    fail("proof manifest must use proof_version 2")
proof_libraries = render_site.selected_libraries_from_proof(proof_file)
reject_duplicates(proof_libraries, field_name="proof libraries")
unknown_proof_libraries = [library for library in proof_libraries if library not in manifest_set]
if unknown_proof_libraries:
    fail(f"proof libraries contain unknown names: {', '.join(unknown_proof_libraries)}")

reject_duplicates(cli_libraries, field_name="--library")
unknown_cli_libraries = [library for library in cli_libraries if library not in manifest_set]
if unknown_cli_libraries:
    fail(f"--library contains unknown names: {', '.join(unknown_cli_libraries)}")
if cli_libraries:
    if cli_libraries != proof_libraries:
        fail("--library selections must exactly match proof libraries in proof order")
    selected_libraries = cli_libraries
else:
    selected_libraries = proof_libraries

expected_proof = validator_call(
    "rebuild proof",
    proof_tools.build_proof,
    manifest,
    artifact_root=artifacts_root,
    tests_root=tests_root,
    libraries=selected_libraries,
    require_casts=True,
)
if expected_proof != proof_file:
    fail("proof manifest does not match rebuilt proof")

site_data_path = site_root / "site-data.json"
site_data = load_json_object(site_data_path, description="site-data.json")
if set(site_data) != {"schema_version", "proof", "testcases"}:
    fail("site-data.json must define exactly schema_version, proof, and testcases")
if site_data.get("schema_version") != 1:
    fail("site-data.json schema_version must be 1")
if not isinstance(site_data.get("proof"), dict):
    fail("site-data.json proof must be an object")
if not isinstance(site_data.get("testcases"), list):
    fail("site-data.json testcases must be a list")

expected_site_data = validator_call(
    "build expected site data",
    render_site.build_site_data,
    proof_file,
    artifact_root=artifacts_root,
    output_root=site_root,
    copy_evidence=False,
)
if site_data != expected_site_data:
    fail("site-data.json does not match proof plus deterministic evidence hrefs")

expected_rows = expected_site_data["testcases"]
row_keys = {
    "library",
    "testcase_id",
    "mode",
    "title",
    "description",
    "kind",
    "client_application",
    "tags",
    "status",
    "duration_seconds",
    "result_path",
    "log_path",
    "cast_path",
    "log_href",
    "cast_href",
}
for row in site_data["testcases"]:
    if not isinstance(row, dict) or set(row) != row_keys:
        fail(f"site testcase row has unexpected shape: {row!r}")
if site_data["testcases"] != expected_rows:
    fail("site-data.json testcase rows do not match proof order and fields")

for row in expected_rows:
    row_name = f"{row['library']}/{row['testcase_id']}"
    log_source = artifact_source(
        row["log_path"],
        field_name="log_path",
        source=row_name,
        artifacts_root=artifacts_root,
    )
    log_target = resolve_inside(site_root, row["log_href"], field_name="log_href", source=row_name)
    if not log_target.is_file():
        fail(f"missing copied log evidence for {row_name}: {row['log_href']}")
    if log_target.read_bytes() != log_source.read_bytes():
        fail(f"copied log evidence does not match source for {row_name}")

    cast_source = artifact_source(
        row["cast_path"],
        field_name="cast_path",
        source=row_name,
        artifacts_root=artifacts_root,
    )
    cast_target = resolve_inside(site_root, row["cast_href"], field_name="cast_href", source=row_name)
    if not cast_target.is_file():
        fail(f"missing copied cast evidence for {row_name}: {row['cast_href']}")
    if cast_target.read_bytes() != cast_source.read_bytes():
        fail(f"copied cast evidence does not match source for {row_name}")

index_path = site_root / "index.html"
if not index_path.is_file():
    fail(f"missing rendered index.html: {index_path}")
html_paths = [index_path, *sorted((site_root / "library").glob("*.html"))]
html_by_path = {path: path.read_text() for path in html_paths}
html_text = "\n".join(html_by_path.values())

html_without_case_rows = re.sub(
    r'<details class="case-row"(?=[\s>]).*?</details>',
    "",
    html_text,
    flags=re.IGNORECASE | re.DOTALL,
)
if re.search(r"\bsafe\b|\bunsafe\b|safe[- ]workload", html_without_case_rows, flags=re.IGNORECASE):
    fail("rendered HTML contains final user-facing safe/unsafe language")

for row in expected_rows:
    escaped_library = html.escape(str(row["library"]))
    escaped_case = html.escape(str(row["testcase_id"]))
    escaped_cast = html.escape(str(row["cast_href"]))
    pattern = (
        rf'data-library="{re.escape(escaped_library)}"'
        rf'[^>]*data-testcase-id="{re.escape(escaped_case)}"'
        rf'[^>]*data-player-cast="{re.escape(escaped_cast)}"'
    )
    if re.search(pattern, html_text) is None:
        fail(f"missing testcase HTML row for {row['library']}/{row['testcase_id']}")

proof_totals = proof_file.get("totals")
if not isinstance(proof_totals, dict):
    fail("proof totals must be an object")
for field_name in ("libraries", "cases", "source_cases", "usage_cases", "passed", "failed", "casts"):
    marker = f'data-proof-total="{field_name}"'
    if marker not in html_text:
        fail(f"missing proof total marker in HTML: {marker}")

library_root = site_root / "library"
expected_html_by_path = {
    index_path: render_site.render_page(expected_site_data),
}
for library in proof_libraries:
    expected_html_by_path[library_root / f"{library}.html"] = render_site.render_page(
        expected_site_data,
        page_depth=1,
        current_library=library,
    )

if set(html_by_path) != set(expected_html_by_path):
    fail("rendered HTML page set does not match proof libraries")
for path, expected_html in expected_html_by_path.items():
    if html_by_path[path] != expected_html:
        fail(f"rendered HTML does not match deterministic render: {path.relative_to(site_root)}")
PY
