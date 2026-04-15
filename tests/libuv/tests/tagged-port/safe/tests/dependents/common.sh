#!/usr/bin/env bash
set -euo pipefail

libuv_note() {
  printf '\n==> %s\n' "$*"
}

libuv_fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

libuv_python_module_file() {
  python3 - "$1" <<'PY'
import importlib
import sys

module = importlib.import_module(sys.argv[1])
path = getattr(module, "__file__", None)
if not path:
    raise SystemExit(f"module has no __file__: {sys.argv[1]}")
print(path)
PY
}

libuv_r_package_shared_object() {
  Rscript - "$1" <<'RS'
args <- commandArgs(trailingOnly = TRUE)
pkg_dir <- system.file(package = args[1])
matches <- list.files(pkg_dir, pattern = "\\.so$", recursive = TRUE, full.names = TRUE)
if (!length(matches)) {
  quit(status = 1)
}
cat(matches[[1]])
RS
}

libuv_record_probe_glob_root() {
  local root="$1"
  [[ -n "${LIBUV_PROBE_STATE_DIR:-}" ]] || libuv_fail "LIBUV_PROBE_STATE_DIR is not set"
  mkdir -p "${LIBUV_PROBE_STATE_DIR}"
  printf '%s\n' "$(realpath "${root}")" >"${LIBUV_PROBE_STATE_DIR}/probe_glob_root"
}

libuv_probe_glob_root() {
  local state_file
  [[ -n "${LIBUV_PROBE_STATE_DIR:-}" ]] || libuv_fail "LIBUV_PROBE_STATE_DIR is not set"
  state_file="${LIBUV_PROBE_STATE_DIR}/probe_glob_root"
  [[ -f "${state_file}" ]] || libuv_fail "missing probe-glob root marker: ${state_file}"
  cat "${state_file}"
}

libuv_resolve_probe_glob() {
  local pattern="$1"
  python3 - "$(libuv_probe_glob_root)" "${pattern}" <<'PY'
import glob
import sys
from pathlib import Path

root = Path(sys.argv[1])
pattern = sys.argv[2]
matches = sorted(str(path) for path in root.glob(pattern))
if not matches:
    raise SystemExit(f"probe-glob did not match anything under {root}: {pattern}")
if len(matches) != 1:
    raise SystemExit(f"probe-glob matched multiple paths under {root}: {pattern} -> {matches}")
print(matches[0])
PY
}

libuv_init_expected_libuv() {
  case "${LIBUV_EXPECTED_LIBUV_MODE:-}" in
    package)
      LIBUV_EXPECTED_LIBUV_PATH="$(dpkg -L libuv1t64 | awk '/\/libuv\.so\.1$/ { print; exit }')"
      [[ -n "${LIBUV_EXPECTED_LIBUV_PATH}" ]] || libuv_fail "could not find installed libuv.so.1 in libuv1t64"
      LIBUV_EXPECTED_LIBUV_REALPATH="$(realpath "${LIBUV_EXPECTED_LIBUV_PATH}")"
      dpkg -S "${LIBUV_EXPECTED_LIBUV_REALPATH}" 2>/dev/null | grep -q '^libuv1t64:' || \
        libuv_fail "installed libuv realpath is not owned by libuv1t64: ${LIBUV_EXPECTED_LIBUV_REALPATH}"
      ;;
    path)
      [[ -n "${LIBUV_EXPECTED_LIBUV_PATH:-}" ]] || libuv_fail "LIBUV_EXPECTED_LIBUV_PATH is not set"
      [[ -e "${LIBUV_EXPECTED_LIBUV_PATH}" ]] || \
        libuv_fail "expected libuv path does not exist: ${LIBUV_EXPECTED_LIBUV_PATH}"
      LIBUV_EXPECTED_LIBUV_REALPATH="$(realpath "${LIBUV_EXPECTED_LIBUV_PATH}")"
      ;;
    *)
      libuv_fail "unsupported or unset LIBUV_EXPECTED_LIBUV_MODE: ${LIBUV_EXPECTED_LIBUV_MODE:-<unset>}"
      ;;
  esac
}

libuv_resolve_target_libuv() {
  local target="$1"
  local ldd_library_path=""

  [[ -e "${target}" ]] || libuv_fail "target does not exist: ${target}"

  if [[ -n "${LIBUV_LDD_LIBRARY_PATH:-}" && -n "${LD_LIBRARY_PATH:-}" ]]; then
    ldd_library_path="${LIBUV_LDD_LIBRARY_PATH}:${LD_LIBRARY_PATH}"
  elif [[ -n "${LIBUV_LDD_LIBRARY_PATH:-}" ]]; then
    ldd_library_path="${LIBUV_LDD_LIBRARY_PATH}"
  elif [[ -n "${LD_LIBRARY_PATH:-}" ]]; then
    ldd_library_path="${LD_LIBRARY_PATH}"
  fi

  if [[ -n "${ldd_library_path}" ]]; then
    env LD_LIBRARY_PATH="${ldd_library_path}" ldd "${target}" | awk '/libuv\.so\.1/ { print $3; exit }'
  else
    ldd "${target}" | awk '/libuv\.so\.1/ { print $3; exit }'
  fi
}

libuv_assert_target_uses_expected() {
  local target="$1"
  local resolved
  local resolved_realpath

  libuv_init_expected_libuv
  resolved="$(libuv_resolve_target_libuv "${target}")"
  [[ -n "${resolved}" ]] || libuv_fail "could not resolve libuv for ${target}"
  resolved_realpath="$(realpath "${resolved}")"
  [[ "${resolved_realpath}" = "${LIBUV_EXPECTED_LIBUV_REALPATH}" ]] || \
    libuv_fail "${target} resolved libuv to ${resolved} (realpath ${resolved_realpath}), expected ${LIBUV_EXPECTED_LIBUV_PATH}"

  if [[ "${LIBUV_EXPECTED_LIBUV_MODE}" = "package" ]]; then
    dpkg -S "${resolved}" 2>/dev/null | grep -q '^libuv1t64:' || \
      dpkg -S "${resolved_realpath}" 2>/dev/null | grep -q '^libuv1t64:' || \
      libuv_fail "${target} resolved libuv to non-package-managed path ${resolved}"
  fi
}

libuv_resolve_expected_link_target() {
  local kind="$1"
  local locator="$2"

  case "${kind}" in
    path)
      [[ "${locator}" = /* ]] || libuv_fail "path locator must be absolute: ${locator}"
      printf '%s\n' "${locator}"
      ;;
    python-module)
      libuv_python_module_file "${locator}"
      ;;
    r-package)
      libuv_r_package_shared_object "${locator}"
      ;;
    probe-glob)
      libuv_resolve_probe_glob "${locator}"
      ;;
    *)
      libuv_fail "unsupported expected_link_target kind: ${kind}"
      ;;
  esac
}

libuv_assert_expected_link_target() {
  local kind="$1"
  local locator="$2"
  local target

  target="$(libuv_resolve_expected_link_target "${kind}" "${locator}")"
  libuv_assert_target_uses_expected "${target}"
}
