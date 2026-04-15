#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 (--shared|--static) --build <dir> --tests <comma-list>" >&2
  exit 64
}

mode=""
build_dir=""
tests_csv=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --shared)
      mode="shared"
      shift
      ;;
    --static)
      mode="static"
      shift
      ;;
    --build)
      [[ $# -ge 2 ]] || usage
      build_dir="$2"
      shift 2
      ;;
    --tests)
      [[ $# -ge 2 ]] || usage
      tests_csv="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

[[ -n "${mode}" && -n "${build_dir}" && -n "${tests_csv}" ]] || usage

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
safe_root="$(cd "${script_dir}/.." && pwd)"
repo_root="$(cd "${safe_root}/.." && pwd)"

if [[ "${mode}" == "shared" ]]; then
  binary="${build_dir}/uv_safe_run_tests_shared"
else
  binary="${build_dir}/uv_safe_run_tests_static"
fi

if [[ ! -x "${binary}" ]]; then
  echo "missing built runner: ${binary}" >&2
  exit 1
fi

IFS=',' read -r -a tests <<<"${tests_csv}"
cd "${repo_root}/original"
for test_name in "${tests[@]}"; do
  set +e
  "${binary}" "${test_name}"
  status=$?
  set -e
  if [[ "${status}" -ne 0 && "${status}" -ne 7 ]]; then
    exit "${status}"
  fi
done
