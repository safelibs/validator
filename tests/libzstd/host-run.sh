#!/usr/bin/env bash
set -euo pipefail

readonly LIBRARY="libzstd"
readonly MODE="${VALIDATOR_MODE:?}"
readonly HARNESS_ROOT="${VALIDATOR_HARNESS_ROOT:?}"
readonly DOWNSTREAM_DIR="${VALIDATOR_DOWNSTREAM_DIR:?}"
readonly RAW_DIR="${DOWNSTREAM_DIR}/raw"
readonly CONSOLE_LOG="${RAW_DIR}/console.log"
readonly RESULTS_JSON="${RAW_DIR}/results.json"
readonly SUMMARY_JSON="${DOWNSTREAM_DIR}/summary.json"
readonly CONFIG_JSON="${HARNESS_ROOT}/.validator/${LIBRARY}-${MODE}-config.json"
readonly ORIGINAL_ROOT="${HARNESS_ROOT}/original/libzstd-1.5.5+dfsg2"
readonly SAFE_ROOT="${HARNESS_ROOT}/safe"

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
EOF
  chmod +x "${HARNESS_ROOT}/.validator/runtime_helpers.sh"
}

prepare_baseline_launcher() {
  local source_path="${HARNESS_ROOT}/tests/run.sh"
  local launcher_path="${HARNESS_ROOT}/.validator/libzstd-baseline-run.sh"

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
text = text.replace(needle, replacement, 1)
text = text.replace('Path("/validator/tests/libzstd/tests/tagged-port")', 'Path("/work")')
text = text.replace('"$library_tests_root/fixtures/dependents.json"', '"/work/dependents.json"')
dest.write_text(text, encoding="utf-8")
dest.chmod(0o755)
PY
}

build_baseline_config() {
  python3 - "${CONFIG_JSON}" <<'PY'
import json
import sys
from pathlib import Path

selected = [
    "validate-dependent-matrix",
    "frame_probe",
    "legacy_decode",
    "invalid_dictionaries_driver",
    "bigdict_driver",
    "paramgrill_driver",
    "external_matchfinder_driver",
    "dict_builder_driver",
    "simple_compression",
    "simple_decompression",
    "run_zstreamtest",
    "run_pooltests",
    "offline_regression",
    "dependent-compile:apt",
    "dependent-compile:dpkg",
    "dependent-compile:rsync",
    "dependent-compile:systemd",
    "dependent-compile:libarchive",
    "dependent-compile:btrfs-progs",
    "dependent-compile:squashfs-tools",
    "dependent-compile:qemu",
    "dependent-compile:curl",
    "dependent-compile:tiff",
    "dependent-compile:rpm",
    "dependent-compile:zarchive",
]

config = {
    "library": "libzstd",
    "mode": "original",
    "report_format": "validator-wrapper-baseline",
    "selected_dependents": selected,
    "expected_dependents": len(selected),
    "setup_notes": "The libzstd baseline wrapper failed before launching the scratch-local baseline launcher.",
    "failure_notes": "The scratch-local libzstd baseline launcher exited non-zero; consult raw/console.log.",
}

Path(sys.argv[1]).write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
PY
}

build_imported_config() {
  python3 - "${HARNESS_ROOT}/dependents.json" "${CONFIG_JSON}" <<'PY'
import json
import sys
from pathlib import Path

dependents = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
selected = []
markers = []

for entry in dependents["packages"]:
    source = entry["source_package"]
    binary = entry["binary_package"]
    selected.append(f"compile:{source}")
    markers.append({"id": f"compile:{source}", "marker": f"compiled {source}:"})
for entry in dependents["packages"]:
    source = entry["source_package"]
    binary = entry["binary_package"]
    selected.append(f"runtime:{source}")
    markers.append({"id": f"runtime:{source}", "marker": f"== {source} ({binary}) =="})

config = {
    "library": "libzstd",
    "mode": "safe",
    "report_format": "imported-log-marker",
    "selected_dependents": selected,
    "expected_dependents": len(selected),
    "markers": markers,
    "setup_notes": "The libzstd host wrapper failed before launching ./test-original.sh.",
    "pre_marker_notes": (
        "The imported libzstd safe harness failed before the first compile or runtime marker; "
        "the synthesized Phase 4 layout or dependent-image setup failed before matrix execution."
    ),
    "missing_marker_notes": (
        "The imported libzstd safe harness exited successfully without emitting the full "
        "compile and runtime marker sequence."
    ),
    "post_marker_failure_notes": "The imported libzstd safe harness stopped after starting a dependent workload.",
}

Path(sys.argv[2]).write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
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
    notes = normalize_notes(config.get("failure_notes"))
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

prepare_safe_packages_dir() {
  local package_dir="${SAFE_ROOT}/out/deb/default/packages"
  local source_path

  rm -rf "${SAFE_ROOT}/out/deb/default" \
         "${SAFE_ROOT}/out/install/release-default" \
         "${SAFE_ROOT}/out/original-cli" \
         "${SAFE_ROOT}/out/debian-src/default" \
         "${SAFE_ROOT}/out/dependents"
  mkdir -p "${package_dir}"

  for source_path in \
    "$(find_exactly_one_deb "${HARNESS_ROOT}/safe/dist/libzstd1_*.deb")" \
    "$(find_exactly_one_deb "${HARNESS_ROOT}/safe/dist/libzstd-dev_*.deb")" \
    "$(find_exactly_one_deb "${HARNESS_ROOT}/safe/dist/zstd_*.deb")"
  do
    cp -f "${source_path}" "${package_dir}/"
  done
}

prepare_install_roots() {
  local package_dir="${SAFE_ROOT}/out/deb/default/packages"
  local install_root="${SAFE_ROOT}/out/deb/default/stage-root"
  local canonical_root="${SAFE_ROOT}/out/install/release-default"
  local deb_path

  mkdir -p "${install_root}" "${canonical_root}"
  shopt -s nullglob
  for deb_path in "${package_dir}"/*.deb; do
    dpkg-deb -x "${deb_path}" "${install_root}"
  done
  shopt -u nullglob
  rsync -a --delete "${install_root}/" "${canonical_root}/"
}

write_helper_overlay() {
  local helper_root="${SAFE_ROOT}/out/original-cli/lib"
  local canonical_root="${SAFE_ROOT}/out/install/release-default"
  local install_libdir="${canonical_root}/usr/lib"
  local multiarch=""

  if command -v dpkg-architecture >/dev/null 2>&1; then
    multiarch="$(dpkg-architecture -qDEB_HOST_MULTIARCH)"
  elif command -v gcc >/dev/null 2>&1; then
    multiarch="$(gcc -print-multiarch)"
  fi

  if [[ -n "${multiarch}" && -d "${canonical_root}/usr/lib/${multiarch}" ]]; then
    install_libdir="${canonical_root}/usr/lib/${multiarch}"
  fi

  rm -rf "${helper_root}"
  mkdir -p "${helper_root}"
  cp -f "${ORIGINAL_ROOT}/lib/Makefile" "${helper_root}/Makefile"
  cp -f "${ORIGINAL_ROOT}/lib/libzstd.mk" "${helper_root}/libzstd.mk"
  cp -a "${ORIGINAL_ROOT}/lib/common" "${helper_root}/common"
  cp -a "${ORIGINAL_ROOT}/lib/legacy" "${helper_root}/legacy"
  cp -f "${canonical_root}/usr/include/zstd.h" "${helper_root}/zstd.h"
  cp -f "${canonical_root}/usr/include/zdict.h" "${helper_root}/zdict.h"
  cp -f "${canonical_root}/usr/include/zstd_errors.h" "${helper_root}/zstd_errors.h"
  cp -f "${install_libdir}/libzstd.so.1.5.5" "${helper_root}/libzstd.so.1.5.5"
  ln -sfn libzstd.so.1.5.5 "${helper_root}/libzstd.so"
  ln -sfn libzstd.so.1.5.5 "${helper_root}/libzstd.so.1"
  printf 'INPUT ( libzstd.so )\n' >"${helper_root}/libzstd.a"
}

stage_safe_source_tree() {
  local stage_root="${SAFE_ROOT}/out/debian-src/default/libzstd-1.5.5+dfsg2"

  mkdir -p "${stage_root}"
  rsync -a --delete --exclude 'out' "${SAFE_ROOT}/" "${stage_root}/"
}

write_metadata_env() {
  local metadata_path="${SAFE_ROOT}/out/deb/default/metadata.env"
  local stage_root="${SAFE_ROOT}/out/debian-src/default/libzstd-1.5.5+dfsg2"
  local package_dir="${SAFE_ROOT}/out/deb/default/packages"
  local install_root="${SAFE_ROOT}/out/deb/default/stage-root"
  local canonical_root="${SAFE_ROOT}/out/install/release-default"
  local helper_root="${SAFE_ROOT}/out/original-cli/lib"
  local multiarch=""

  if command -v dpkg-architecture >/dev/null 2>&1; then
    multiarch="$(dpkg-architecture -qDEB_HOST_MULTIARCH)"
  elif command -v gcc >/dev/null 2>&1; then
    multiarch="$(gcc -print-multiarch)"
  fi

  cat >"${metadata_path}" <<EOF
BUILD_TAG=default
STAGE_ROOT='${stage_root}'
PACKAGE_DIR='${package_dir}'
INSTALL_ROOT='${install_root}'
MULTIARCH='${multiarch}'
CANONICAL_INSTALL_ROOT='${canonical_root}'
CANONICAL_HELPER_ROOT='${helper_root}'
EOF
}

write_build_helper() {
  local helper_path="${HARNESS_ROOT}/.validator/build-dependent-image-from-prebuilt.sh"

  cat >"${helper_path}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
SAFE_ROOT="${REPO_ROOT}/safe"
DEPENDENT_ROOT="${SAFE_ROOT}/out/dependents"
IMAGE_CONTEXT_ROOT="${DEPENDENT_ROOT}/image-context"
LOG_ROOT="${DEPENDENT_ROOT}/logs"
COMPILE_ROOT="${DEPENDENT_ROOT}/compile-compat"
IMAGE_METADATA_FILE="${IMAGE_CONTEXT_ROOT}/metadata.env"
DEPENDENT_BASE_IMAGE='ubuntu:24.04'

source "${SAFE_ROOT}/scripts/phase6-common.sh"
phase6_require_phase4_inputs "$0"

dependent_image_fingerprint() {
  {
    printf '%s\n' "${DEPENDENT_BASE_IMAGE}"
    sha256sum \
      "${REPO_ROOT}/dependents.json" \
      "${SAFE_ROOT}/docker/dependents/Dockerfile" \
      "${SAFE_ROOT}/docker/dependents/entrypoint.sh" \
      "${SAFE_ROOT}/scripts/check-dependent-compile-compat.sh" \
      "${SAFE_ROOT}/out/deb/default/metadata.env" \
      "${PHASE6_DEB_PACKAGE_DIR}"/*.deb
    find "${SAFE_ROOT}/tests/dependents" -type f -print0 | sort -z | xargs -0 sha256sum
  } | sha256sum | cut -c1-16
}

DEPENDENT_IMAGE="safelibs-libzstd-dependents:$(dependent_image_fingerprint)"

rm -rf "${IMAGE_CONTEXT_ROOT}"
install -d \
  "${IMAGE_CONTEXT_ROOT}" \
  "${IMAGE_CONTEXT_ROOT}/safe/out/deb/default/packages" \
  "${IMAGE_CONTEXT_ROOT}/safe/tests/dependents" \
  "${IMAGE_CONTEXT_ROOT}/safe/scripts" \
  "${IMAGE_CONTEXT_ROOT}/safe/docker/dependents" \
  "${LOG_ROOT}" \
  "${COMPILE_ROOT}"

install -m 644 "${REPO_ROOT}/dependents.json" "${IMAGE_CONTEXT_ROOT}/dependents.json"
install -m 644 "${SAFE_ROOT}/out/deb/default/metadata.env" "${IMAGE_CONTEXT_ROOT}/safe/out/deb/default/metadata.env"
install -m 755 \
  "${SAFE_ROOT}/scripts/check-dependent-compile-compat.sh" \
  "${IMAGE_CONTEXT_ROOT}/safe/scripts/check-dependent-compile-compat.sh"
install -m 755 \
  "${SAFE_ROOT}/docker/dependents/entrypoint.sh" \
  "${IMAGE_CONTEXT_ROOT}/safe/docker/dependents/entrypoint.sh"
rsync -a --delete "${PHASE6_DEB_PACKAGE_DIR}/" "${IMAGE_CONTEXT_ROOT}/safe/out/deb/default/packages/"
rsync -a --delete "${SAFE_ROOT}/tests/dependents/" "${IMAGE_CONTEXT_ROOT}/safe/tests/dependents/"

cat >"${IMAGE_METADATA_FILE}" <<EOF2
DEPENDENT_IMAGE='${DEPENDENT_IMAGE}'
DEPENDENT_BASE_IMAGE='${DEPENDENT_BASE_IMAGE}'
EOF2

build_dependent_image() {
  local cache_mode=${1:-}
  local -a build_args=(
    docker build
  )

  if [[ "${cache_mode}" == "--no-cache" ]]; then
    build_args+=(--no-cache)
  fi

  build_args+=(
    --build-arg "BASE_IMAGE=${DEPENDENT_BASE_IMAGE}"
    --file "${SAFE_ROOT}/docker/dependents/Dockerfile"
    --tag "${DEPENDENT_IMAGE}"
    "${IMAGE_CONTEXT_ROOT}"
  )
  "${build_args[@]}"
}

preflight_dependent_image() {
  local log_path="${IMAGE_CONTEXT_ROOT}/preflight-libarchive.log"
  docker run --rm \
    --privileged \
    --tmpfs /run \
    --tmpfs /run/lock \
    "${DEPENDENT_IMAGE}" \
    runtime libarchive >"${log_path}" 2>&1
}

build_dependent_image
if ! preflight_dependent_image; then
  phase6_log "dependent image ${DEPENDENT_IMAGE} failed libarchive preflight; rebuilding without Docker layer cache"
  build_dependent_image --no-cache
  if ! preflight_dependent_image; then
    cat "${IMAGE_CONTEXT_ROOT}/preflight-libarchive.log" >&2
    exit 1
  fi
fi

phase6_log "built dependent image ${DEPENDENT_IMAGE} from ${DEPENDENT_BASE_IMAGE}"
phase6_log "staged image context under ${IMAGE_CONTEXT_ROOT}"
EOF
  chmod +x "${helper_path}"
}

patch_test_original() {
  python3 - "${HARNESS_ROOT}/test-original.sh" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
needle = 'bash "$SAFE_ROOT/scripts/build-dependent-image.sh"\n'
replacement = 'bash "$REPO_ROOT/.validator/build-dependent-image-from-prebuilt.sh"\n'
if needle not in text:
    raise SystemExit(f"missing expected build-dependent-image invocation in {path}")
path.write_text(text.replace(needle, replacement, 1), encoding="utf-8")
PY
}

prepare_safe_mode_layout() {
  prepare_safe_packages_dir
  prepare_install_roots
  write_helper_overlay
  stage_safe_source_tree
  write_metadata_env
  write_build_helper
  patch_test_original
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
      bash /work/.validator/libzstd-baseline-run.sh
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
  if prepare_safe_mode_layout; then
    status=0
  else
    status=$?
    failure_mode="setup"
    finalize_imported_summary "${status}" "${failure_mode}"
    return "${status}"
  fi

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
