#!/usr/bin/env bash
set -euo pipefail

readonly LIBRARY="libvips"
readonly MODE="${VALIDATOR_MODE:?}"
readonly HARNESS_ROOT="${VALIDATOR_HARNESS_ROOT:?}"
readonly DOWNSTREAM_DIR="${VALIDATOR_DOWNSTREAM_DIR:?}"
readonly RAW_DIR="${DOWNSTREAM_DIR}/raw"
readonly CONSOLE_LOG="${RAW_DIR}/console.log"
readonly RESULTS_JSON="${RAW_DIR}/results.json"
readonly SUMMARY_JSON="${DOWNSTREAM_DIR}/summary.json"
readonly CONFIG_JSON="${HARNESS_ROOT}/.validator/${LIBRARY}-${MODE}-config.json"
readonly WRAPPER_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${RAW_DIR}" "${HARNESS_ROOT}/.validator"

run_captured() {
  : >"${CONSOLE_LOG}"
  set +e
  "$@" 2>&1 | tee "${CONSOLE_LOG}"
  local status=${PIPESTATUS[0]}
  set -e
  return "${status}"
}

find_exactly_one_deb() {
  local pattern=$1
  local matches=()

  shopt -s nullglob
  matches=(${pattern})
  shopt -u nullglob

  if [[ ${#matches[@]} -ne 1 ]]; then
    printf 'expected exactly one package matching %s\n' "${pattern}" >&2
    return 1
  fi

  printf '%s\n' "${matches[0]}"
}

write_runtime_helpers() {
  cat >"${HARNESS_ROOT}/.validator/runtime_helpers.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

validator_require_file() {
  local path=$1
  [[ -f "$path" ]] || {
    printf 'missing required file: %s\n' "$path" >&2
    exit 1
  }
}

validator_require_dir() {
  local path=$1
  [[ -d "$path" ]] || {
    printf 'missing required directory: %s\n' "$path" >&2
    exit 1
  }
}

validator_copy_tree() {
  local source=$1
  local dest=$2
  mkdir -p "$(dirname "$dest")"
  cp -a "$source" "$dest"
}

validator_make_tool_shims() {
  local dest_dir=$1
  shift

  mkdir -p "$dest_dir"
  while (($#)); do
    local tool=$1
    local target
    shift

    target=$(command -v "$tool") || {
      printf 'missing required command: %s\n' "$tool" >&2
      exit 1
    }
    ln -sf "$target" "$dest_dir/$tool"
  done
}
EOF
  chmod +x "${HARNESS_ROOT}/.validator/runtime_helpers.sh"
}

prepare_baseline_launcher() {
  local source_path="${WRAPPER_ROOT}/tests/run.sh"
  local launcher_path="${HARNESS_ROOT}/.validator/libvips-baseline-run.sh"

  write_runtime_helpers

  python3 - "${source_path}" "${launcher_path}" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1])
dest = Path(sys.argv[2])
text = source.read_text(encoding="utf-8")
needle = "source /validator/tests/_shared/runtime_helpers.sh\n"
replacement = "source /work/.validator/runtime_helpers.sh\n"
if needle not in text:
    raise SystemExit(f"missing expected runtime helper source line in {source}")
dest.write_text(text.replace(needle, replacement, 1), encoding="utf-8")
dest.chmod(0o755)
PY
}

prepare_safe_packages() {
  local package
  local source_path

  for package in libvips42t64 libvips-dev libvips-tools libvips-doc gir1.2-vips-8.0; do
    if ! source_path="$(find_exactly_one_deb "${HARNESS_ROOT}/safe/dist/${package}_*.deb")"; then
      return 1
    fi
    cp -f "${source_path}" "${HARNESS_ROOT}/"
  done
}

patch_safe_apt_retries() {
  python3 - "${HARNESS_ROOT}/safe/tests/dependents/lib.sh" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
needle = "set -euo pipefail\n\n"
injection = """set -euo pipefail

apt-get() {
  local mirror="${VALIDATOR_APT_MIRROR:-http://azure.archive.ubuntu.com/ubuntu}"
  local source_file
  for source_file in /etc/apt/sources.list /etc/apt/sources.list.d/*.sources; do
    [[ -e "${source_file}" ]] || continue
    sed -i -E "s#http://([a-z]{2}\\.)?archive\\.ubuntu\\.com/ubuntu#${mirror}#g; s#http://security\\.ubuntu\\.com/ubuntu#${mirror}#g" "${source_file}"
  done
  command apt-get \\
    -o Acquire::ForceIPv4=true \\
    -o Acquire::Retries=10 \\
    -o Acquire::http::Timeout=60 \\
    -o Acquire::https::Timeout=60 \\
    -o Acquire::http::Pipeline-Depth=0 \\
    "$@"
}

"""
if injection in text:
    raise SystemExit(0)
if needle not in text:
    raise SystemExit(f"missing shell strict-mode header in {path}")
path.write_text(text.replace(needle, injection, 1), encoding="utf-8")
PY
}

build_baseline_config() {
  python3 - "${CONFIG_JSON}" <<'PY'
import json
import sys
from pathlib import Path

selected = [
    "compile:test_connections",
    "compile:test_descriptors",
    "compile:test_timeout_webpsave",
    "compile:use-vips-func",
    "run-shell-suite",
    "run-pytest-suite",
    "run-dependent-suite",
]

config = {
    "library": "libvips",
    "mode": "original",
    "report_format": "validator-wrapper-baseline",
    "selected_dependents": selected,
    "expected_dependents": 7,
    "success_notes": (
        "This original-mode summary mirrors the installed-package baseline from "
        "tests/libvips/tests/run.sh rather than the 12-application safe matrix."
    ),
    "setup_notes": "The libvips baseline wrapper failed before launching the scratch-local baseline launcher.",
    "failure_notes": "The scratch-local libvips baseline launcher exited non-zero; consult raw/console.log.",
}

Path(sys.argv[1]).write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
PY
}

build_imported_config() {
  python3 - "${HARNESS_ROOT}/dependents.json" "${HARNESS_ROOT}/safe/tests/dependents/cases" "${CONFIG_JSON}" <<'PY'
import json
import re
import sys
from pathlib import Path

dependents = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
cases_root = Path(sys.argv[2])
selected = [entry["package"] for entry in dependents["selected_applications"]]
pattern = re.compile(r'log "([^"]+)"')
markers = []

for package in selected:
    case_path = cases_root / f"{package}.sh"
    marker = None
    for line in case_path.read_text(encoding="utf-8").splitlines():
        match = pattern.search(line)
        if match:
            marker = match.group(1)
            break
    if marker is None:
        raise SystemExit(f"missing log marker in {case_path}")
    markers.append({"id": package, "marker": marker})

config = {
    "library": "libvips",
    "mode": "safe",
    "report_format": "imported-log-marker",
    "selected_dependents": selected,
    "expected_dependents": len(selected),
    "markers": markers,
    "setup_notes": "The libvips host wrapper failed before launching ./test-original.sh.",
    "pre_marker_notes": (
        "The imported libvips safe harness failed before the first application marker; "
        "package verification or extracted-prefix preparation failed before dependent execution."
    ),
    "missing_marker_notes": (
        "The imported libvips safe harness exited successfully without emitting the full "
        "application marker sequence."
    ),
    "post_marker_failure_notes": "The imported libvips safe harness stopped after starting an application workload.",
}

Path(sys.argv[3]).write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
PY
}

finalize_baseline_summary() {
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

selected = list(config["selected_dependents"])
passed = []
failed = []
warned = []
skipped = []

if failure_mode == "setup":
    selected_for_summary = []
    notes = normalize_notes(config.get("setup_notes"))
    status = "failed"
elif exit_code == 0:
    selected_for_summary = selected
    passed = list(selected)
    notes = normalize_notes(config.get("success_notes"))
    status = "passed"
else:
    selected_for_summary = selected
    failed = selected[:1]
    skipped = selected[1:]
    notes = normalize_notes(config.get("success_notes"), config.get("failure_notes"))
    status = "failed"

status_by_workload = {item: "skipped" for item in selected}
for item in passed:
    status_by_workload[item] = "passed"
for item in failed:
    status_by_workload[item] = "failed"

results_payload = {
    "schema_version": 1,
    "library": config["library"],
    "mode": config["mode"],
    "report_format": config["report_format"],
    "exit_code": exit_code,
    "failure_mode": failure_mode,
    "selected_dependents": selected,
    "workloads": [{"id": item, "status": status_by_workload[item]} for item in selected],
}
results_path.write_text(json.dumps(results_payload, indent=2) + "\n", encoding="utf-8")

summary_payload = {
    "summary_version": 1,
    "library": config["library"],
    "mode": config["mode"],
    "status": status,
    "report_format": config["report_format"],
    "expected_dependents": int(config["expected_dependents"]),
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

finalize_imported_summary() {
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
else:
    if exit_code == 0:
      passed = list(observed_ids)
      if len(observed_ids) < len(selected_full):
          failed = [selected_full[len(observed_ids)]]
          skipped = selected_full[len(observed_ids) + 1 :]
      notes = normalize_notes(notes, config.get("missing_marker_notes"))
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

run_original_mode() {
  local status=0
  local failure_mode="command"

  build_baseline_config
  if prepare_baseline_launcher; then
    status=0
  else
    status=$?
    failure_mode="setup"
    finalize_baseline_summary "${status}" "${failure_mode}"
    return "${status}"
  fi

  if run_captured \
    docker run --rm -i \
      --mount "type=bind,src=${HARNESS_ROOT},dst=/work" \
      -e VALIDATOR_TAGGED_ROOT=/work \
      -e VALIDATOR_LIBRARY_ROOT=/work \
      "${VALIDATOR_BASELINE_IMAGE:?}" \
      bash /work/.validator/libvips-baseline-run.sh
  then
    status=0
  else
    status=$?
  fi

  finalize_baseline_summary "${status}" "${failure_mode}"
  return "${status}"
}

run_safe_mode() {
  local status=0
  local failure_mode="command"

  build_imported_config
  if prepare_safe_packages; then
    status=0
  else
    status=$?
    failure_mode="setup"
    finalize_imported_summary "${status}" "${failure_mode}"
    return "${status}"
  fi
  if patch_safe_apt_retries; then
    status=0
  else
    status=$?
    failure_mode="setup"
    finalize_imported_summary "${status}" "${failure_mode}"
    return "${status}"
  fi

  export LIBVIPS_USE_EXISTING_DEBS=1
  if run_captured ./test-original.sh; then
    status=0
  else
    status=$?
  fi

  finalize_imported_summary "${status}" "${failure_mode}"
  return 0
}

case "${MODE}" in
  original)
    run_original_mode
    ;;
  safe)
    run_safe_mode
    ;;
  *)
    printf 'unsupported mode for %s: %s\n' "${LIBRARY}" "${MODE}" >&2
    exit 1
    ;;
esac
