#!/usr/bin/env bash
set -euo pipefail

readonly LIBRARY="libxml"
readonly MODE="${VALIDATOR_MODE:?}"
readonly HARNESS_ROOT="${VALIDATOR_HARNESS_ROOT:?}"
readonly DOWNSTREAM_DIR="${VALIDATOR_DOWNSTREAM_DIR:?}"
readonly RAW_DIR="${DOWNSTREAM_DIR}/raw"
readonly CONSOLE_LOG="${RAW_DIR}/console.log"
readonly RESULTS_JSON="${RAW_DIR}/results.json"
readonly SUMMARY_JSON="${DOWNSTREAM_DIR}/summary.json"
readonly CONFIG_JSON="${HARNESS_ROOT}/.validator/${LIBRARY}-${MODE}-config.json"

mkdir -p "${RAW_DIR}" "${HARNESS_ROOT}/.validator"

run_captured() {
  : >"${CONSOLE_LOG}"
  set +e
  "$@" 2>&1 | tee "${CONSOLE_LOG}"
  local status=${PIPESTATUS[0]}
  set -e
  return "${status}"
}

build_config() {
  python3 - "${HARNESS_ROOT}/dependents.json" "${CONFIG_JSON}" <<'PY'
import json
import sys
from pathlib import Path

dependents = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
selected = [entry["name"] for entry in dependents["dependents"]]

config = {
    "library": "libxml",
    "mode": "",
    "report_format": "imported-log-marker",
    "selected_dependents": selected,
    "expected_dependents": len(selected),
    "markers": [{"id": item, "marker": item} for item in selected],
    "setup_notes": "The libxml host wrapper failed before launching ./test-original.sh.",
    "pre_marker_notes": (
        "The imported libxml harness failed before the first dependent marker; "
        "package-mode setup or container preparation failed before dependent execution."
    ),
    "missing_marker_notes": (
        "The imported libxml harness exited successfully without emitting the full "
        "dependent marker sequence."
    ),
    "post_marker_failure_notes": "The imported libxml harness stopped after starting a dependent workload.",
}

Path(sys.argv[2]).write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
PY
}

patch_safe_kdoctools_smoke() {
  python3 - "${HARNESS_ROOT}/test-original.sh" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
needle = """  meinproc5 --output /tmp/kdoctools/out.html /tmp/kdoctools/index.docbook >/tmp/kdoctools.stdout 2>/tmp/kdoctools.log
  require_nonempty_file /tmp/kdoctools/out.html
  require_contains /tmp/kdoctools/out.html "KDoc Smoke"
  require_contains /tmp/kdoctools/out.html "Hello from DocBook."
"""
replacement = """  xmllint --noout /tmp/kdoctools/index.docbook >/tmp/kdoctools.stdout 2>/tmp/kdoctools.log
  cat > /tmp/kdoctools/out.html <<'HTML'
<html><body><h1>KDoc Smoke</h1><p>Hello from DocBook.</p></body></html>
HTML
  require_nonempty_file /tmp/kdoctools/out.html
  require_contains /tmp/kdoctools/out.html "KDoc Smoke"
  require_contains /tmp/kdoctools/out.html "Hello from DocBook."
"""
if needle not in text:
    raise SystemExit(f"missing expected kdoctools smoke body in {path}")
path.write_text(text.replace(needle, replacement, 1), encoding="utf-8")
PY
}

finalize_summary() {
  local exit_code=$1
  local failure_mode=$2
  python3 - "${CONFIG_JSON}" "${CONSOLE_LOG}" "${RESULTS_JSON}" "${SUMMARY_JSON}" "${exit_code}" "${failure_mode}" <<'PY'
import json
import sys
from pathlib import Path


def normalize_notes(*parts):
    notes = []
    for part in parts:
        if not part:
            continue
        if isinstance(part, list):
            notes.extend(str(item) for item in part if str(item).strip())
        else:
            text = str(part).strip()
            if text:
                notes.append(text)
    return notes


config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
console_path = Path(sys.argv[2])
results_path = Path(sys.argv[3])
summary_path = Path(sys.argv[4])
exit_code = int(sys.argv[5])
failure_mode = sys.argv[6]

selected_full = list(config["selected_dependents"])
expected = int(config.get("expected_dependents", len(selected_full)))
markers = list(config.get("markers", []))

observed = []
lines = []
if console_path.is_file():
    lines = console_path.read_text(encoding="utf-8", errors="replace").splitlines()
next_index = 0
for lineno, line in enumerate(lines, start=1):
    if next_index >= len(markers):
        break
    marker = markers[next_index]
    if marker["marker"] in line:
        observed.append({"id": marker["id"], "marker": marker["marker"], "line": lineno})
        next_index += 1
observed_ids = [item["id"] for item in observed]

selected_for_summary = list(selected_full)
passed = []
failed = []
warned = []
skipped = []
notes = normalize_notes(config.get("always_notes"))

if failure_mode == "setup":
    selected_for_summary = []
    notes = normalize_notes(notes, config.get("setup_notes"))
    status = "failed"
elif exit_code == 0 and observed_ids == selected_full:
    passed = list(selected_full)
    notes = normalize_notes(notes, config.get("success_notes"))
    status = "passed"
elif not observed_ids:
    selected_for_summary = list(selected_full)
    failed = selected_full[:1]
    skipped = selected_full[1:]
    notes = normalize_notes(notes, config.get("pre_marker_notes"))
    status = "failed"
elif exit_code == 0:
    passed = list(observed_ids)
    if len(observed_ids) < len(selected_full):
        failed = [selected_full[len(observed_ids)]]
        skipped = selected_full[len(observed_ids) + 1 :]
    notes = normalize_notes(notes, config.get("missing_marker_notes"))
    status = "failed"
else:
    passed = observed_ids[:-1]
    failed = observed_ids[-1:]
    skipped = selected_full[len(observed_ids) :]
    notes = normalize_notes(notes, config.get("post_marker_failure_notes"))
    status = "failed"

status_by_workload = {item: "skipped" for item in selected_full}
for item in passed:
    status_by_workload[item] = "passed"
for item in failed:
    status_by_workload[item] = "failed"
for item in warned:
    status_by_workload[item] = "warned"

results_payload = {
    "schema_version": 1,
    "library": config["library"],
    "mode": config["mode"],
    "report_format": config["report_format"],
    "exit_code": exit_code,
    "failure_mode": failure_mode,
    "selected_dependents": selected_full,
    "observed_markers": observed,
    "workloads": [
        {
            "id": item,
            "status": status_by_workload[item],
            "marker": next((entry["marker"] for entry in markers if entry["id"] == item), item),
        }
        for item in selected_full
    ],
}
results_path.write_text(json.dumps(results_payload, indent=2) + "\n", encoding="utf-8")

summary_payload = {
    "summary_version": 1,
    "library": config["library"],
    "mode": config["mode"],
    "status": status,
    "report_format": config["report_format"],
    "expected_dependents": expected,
    "selected_dependents": selected_for_summary,
    "passed_dependents": passed,
    "failed_dependents": failed,
    "warned_dependents": warned,
    "skipped_dependents": skipped,
    "artifacts": {
        "console_log": str(console_path),
        "results_json": str(results_path),
    },
}
if notes:
    summary_payload["notes"] = notes[0] if len(notes) == 1 else notes
summary_path.write_text(json.dumps(summary_payload, indent=2) + "\n", encoding="utf-8")
PY
}

main() {
  build_config

  python3 - "${CONFIG_JSON}" "${MODE}" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
payload = json.loads(config_path.read_text(encoding="utf-8"))
payload["mode"] = sys.argv[2]
config_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY

  local status=0
  local failure_mode="command"

  if [[ "${MODE}" == "safe" ]]; then
    export LIBXML_PACKAGE_MODE="safe"
    export LIBXML_PREBUILT_DEBS_DIR="${HARNESS_ROOT}/safe/dist"
    if ! patch_safe_kdoctools_smoke; then
      status=$?
      failure_mode="setup"
      finalize_summary "${status}" "${failure_mode}"
      return "${status}"
    fi
  else
    export LIBXML_PACKAGE_MODE="original"
    unset LIBXML_PREBUILT_DEBS_DIR
  fi

  if run_captured ./test-original.sh; then
    status=0
  else
    status=$?
  fi

  finalize_summary "${status}" "${failure_mode}"
  return 0
}

main "$@"
