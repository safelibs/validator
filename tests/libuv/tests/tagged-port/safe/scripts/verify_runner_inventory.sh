#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0" >&2
  exit 64
}

count_entries() {
  local binary="$1"
  [[ -x "${binary}" ]] || {
    echo "missing runner binary: ${binary}" >&2
    exit 1
  }
  "${binary}" --list | awk 'END { print NR }'
}

assert_counts() {
  local dir="$1"
  local expected_shared="$2"
  local expected_static="$3"
  local expected_bench="$4"
  local shared_count
  local static_count
  local bench_count

  shared_count="$(count_entries "${dir}/uv_run_tests")"
  static_count="$(count_entries "${dir}/uv_run_tests_a")"
  bench_count="$(count_entries "${dir}/uv_run_benchmarks_a")"

  [[ "${shared_count}" == "${expected_shared}" ]] || {
    echo "unexpected shared runner count in ${dir}: ${shared_count} (expected ${expected_shared})" >&2
    exit 1
  }
  [[ "${static_count}" == "${expected_static}" ]] || {
    echo "unexpected static runner count in ${dir}: ${static_count} (expected ${expected_static})" >&2
    exit 1
  }
  [[ "${bench_count}" == "${expected_bench}" ]] || {
    echo "unexpected benchmark runner count in ${dir}: ${bench_count} (expected ${expected_bench})" >&2
    exit 1
  }
}

[[ $# -eq 0 ]] || usage

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
safe_root="$(cd "${script_dir}/.." && pwd)"
repo_root="$(cd "${safe_root}/.." && pwd)"

assert_counts "${repo_root}/original/build-checker" 435 435 55
assert_counts "${repo_root}/original/build-checker-review" 440 440 55
assert_counts "${repo_root}/original/build-checker-verify" 440 440 55
assert_counts "${repo_root}/original/build-checker-audit" 440 440 55
