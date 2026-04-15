#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
safe_dir=$(cd -- "$script_dir/.." && pwd)
repo_dir=$(cd -- "$safe_dir/.." && pwd)
image_tag="${LIBSODIUM_DEPENDENT_IMAGE:-${LIBSODIUM_ORIGINAL_TEST_IMAGE:-libsodium-original-test:ubuntu24.04}}"

usage() {
  cat <<EOF
usage: $(basename "$0") [--report-dir <dir>] [--mode safe|original] [--only <package>] [--from-list <file>] [--strict]

Runs the dependent compatibility matrix through test-original.sh and writes a
deterministic report ledger under the requested report directory. In safe mode,
the default report directory is safe/compat-reports/dependents/ for a full
matrix run and safe/compat-reports/dependents-rerun/ when --from-list is used.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

resolve_report_dir() {
  local input="$1"
  local parent
  local base

  parent="$(dirname -- "$input")"
  base="$(basename -- "$input")"
  mkdir -p "$parent"
  parent="$(cd -- "$parent" && pwd)"
  printf '%s/%s\n' "$parent" "$base"
}

default_report_dir() {
  case "$mode" in
    safe)
      if [[ -n "$from_list" ]]; then
        printf '%s/compat-reports/dependents-rerun\n' "$safe_dir"
      else
        printf '%s/compat-reports/dependents\n' "$safe_dir"
      fi
      ;;
    original)
      die "missing required --report-dir in original mode"
      ;;
  esac
}

clear_report_dir() {
  local report_dir="$1"
  local host_uid
  local host_gid

  host_uid="$(id -u)"
  host_gid="$(id -g)"

  docker run --rm \
    -v "$report_dir":/reports \
    "$image_tag" \
    bash -lc "
      set -euo pipefail
      find /reports -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
      chown -R $host_uid:$host_gid /reports
    "
}

mode="safe"
report_dir=""
only=""
from_list=""
strict=0

while (($#)); do
  case "$1" in
    --mode)
      mode="${2:?missing value for --mode}"
      shift 2
      ;;
    --report-dir)
      report_dir="${2:?missing value for --report-dir}"
      shift 2
      ;;
    --only)
      only="${2:?missing value for --only}"
      shift 2
      ;;
    --from-list)
      from_list="${2:?missing value for --from-list}"
      shift 2
      ;;
    --strict)
      strict=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

[[ -z "$only" || -z "$from_list" ]] || die "--only and --from-list are mutually exclusive"

case "$mode" in
  safe|original)
    ;;
  *)
    die "unknown mode: $mode"
    ;;
esac

if [[ -z "$report_dir" ]]; then
  report_dir="$(default_report_dir)"
fi
report_dir="$(resolve_report_dir "$report_dir")"
mkdir -p "$report_dir"
"$safe_dir/tools/build-dependent-image.sh" --tag "$image_tag"
clear_report_dir "$report_dir"

args=(
  --mode "$mode"
  --report-dir "$report_dir"
)

if [[ -n "$only" ]]; then
  args+=(--only "$only")
fi
if [[ -n "$from_list" ]]; then
  args+=(--from-list "$from_list")
fi
if [[ "$strict" == "1" ]]; then
  args+=(--strict)
fi

LIBSODIUM_SKIP_IMAGE_BUILD=1 "$repo_dir/test-original.sh" "${args[@]}"

if [[ -s "$report_dir/failures.list" ]]; then
  printf '\nFAIL/WARN rows persisted in %s:\n' "$report_dir/failures.list"
  sed -n '1,200p' "$report_dir/failures.list"
else
  printf '\nNo FAIL or WARN rows were recorded in %s.\n' "$report_dir/failures.list"
fi
