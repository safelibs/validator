#!/usr/bin/env bash
set -euo pipefail

config=
results_root=
site_root=
artifacts_root=

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
    --site-root)
      site_root=$2
      shift 2
      ;;
    *)
      echo "unexpected argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$config" || -z "$results_root" || -z "$site_root" ]]; then
  echo "usage: verify-site.sh --config <manifest> --results-root <dir> [--artifacts-root <dir>] --site-root <dir>" >&2
  exit 1
fi

python3 - "$config" "$results_root" "$site_root" "$artifacts_root" <<'PY'
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import yaml


config_path = Path(sys.argv[1])
results_root = Path(sys.argv[2])
site_root = Path(sys.argv[3])
artifacts_root_arg = sys.argv[4]
artifacts_root = Path(artifacts_root_arg) if artifacts_root_arg else results_root.parent
artifacts_root_resolved = artifacts_root.resolve()

manifest = yaml.safe_load(config_path.read_text())
manifest_libraries = [entry["name"] for entry in manifest["repositories"]]
manifest_set = set(manifest_libraries)


def validate_relative_artifact_path(value: str | None, *, field_name: str, source: str) -> Path | None:
    if value is None:
        return None
    if not isinstance(value, str) or not value:
        raise SystemExit(f"{field_name} must be a non-empty artifact-root-relative path in {source}")
    if "\\" in value:
        raise SystemExit(f"{field_name} must use artifact-root-relative paths in {source}")

    relative = Path(value)
    if relative.is_absolute() or any(part in {"", ".", ".."} for part in relative.parts):
        raise SystemExit(f"{field_name} must be artifact-root-relative in {source}")

    target = (artifacts_root / relative).resolve(strict=False)
    try:
        target.relative_to(artifacts_root_resolved)
    except ValueError:
        raise SystemExit(f"{field_name} must stay within the artifact root in {source}")
    return target


def resolve_site_href(value: str | None, *, field_name: str, source: str) -> Path | None:
    if value is None:
        return None
    href_target = (site_root / value).resolve(strict=False)
    try:
        href_target.relative_to(artifacts_root_resolved)
    except ValueError:
        raise SystemExit(f"{field_name} must resolve within the artifact root in {source}")
    return href_target

result_rows = []
for path in sorted(results_root.glob("*/*.json")):
    payload = json.loads(path.read_text())
    library = payload["library"]
    mode = payload["mode"]
    if library not in manifest_set:
        raise SystemExit(f"unexpected library in results: {library}")
    log_target = validate_relative_artifact_path(payload["log_path"], field_name="log_path", source=str(path))
    assert log_target is not None
    if not log_target.is_file():
        raise SystemExit(f"missing log referenced by result JSON: {log_target}")
    cast_path = payload["cast_path"]
    if cast_path is not None:
        cast_target = validate_relative_artifact_path(cast_path, field_name="cast_path", source=str(path))
        assert cast_target is not None
        if not cast_target.is_file():
            raise SystemExit(f"missing cast referenced by result JSON: {cast_target}")
    result_rows.append(
        {
            "library": library,
            "mode": mode,
            "status": payload["status"],
            "log_path": payload["log_path"],
            "cast_path": payload["cast_path"],
        }
    )

site_data_path = site_root / "site-data.json"
if not site_data_path.is_file():
    raise SystemExit(f"missing site-data.json: {site_data_path}")

site_rows = json.loads(site_data_path.read_text()).get("results")
if not isinstance(site_rows, list):
    raise SystemExit(f"site-data.json must define a results list: {site_data_path}")

normalize = lambda rows: sorted(
    [
        {
            "library": row["library"],
            "mode": row["mode"],
            "status": row["status"],
            "log_path": row["log_path"],
            "cast_path": row["cast_path"],
        }
        for row in rows
    ],
    key=lambda row: (row["library"], row["mode"]),
)

if normalize(site_rows) != normalize(result_rows):
    raise SystemExit("site-data.json does not match the result JSON set exactly")

for row in site_rows:
    log_href = row.get("log_href")
    if not log_href:
        raise SystemExit(f"missing log_href in site row: {row}")
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
        raise SystemExit(f"log_href does not match log_path in site row: {row}")
    if not resolved_log_href.is_file():
        raise SystemExit(f"missing log target referenced by site: {log_href}")
    cast_href = row.get("cast_href")
    if row["cast_path"] is None:
        if cast_href is not None:
            raise SystemExit(f"unexpected cast_href for non-cast row: {row}")
    else:
        if not cast_href:
            raise SystemExit(f"missing cast_href for cast row: {row}")
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
            raise SystemExit(f"cast_href does not match cast_path in site row: {row}")
        if not resolved_cast_href.is_file():
            raise SystemExit(f"missing cast target referenced by site: {cast_href}")

index_path = site_root / "index.html"
if not index_path.is_file():
    raise SystemExit(f"missing rendered index.html: {index_path}")

html_text = index_path.read_text()
html_rows = set(re.findall(r'data-library="([^"]+)" data-mode="([^"]+)"', html_text))
expected_rows = {(row["library"], row["mode"]) for row in result_rows}
if html_rows != expected_rows:
    raise SystemExit(f"site index rows mismatch: expected {sorted(expected_rows)}, found {sorted(html_rows)}")
PY
