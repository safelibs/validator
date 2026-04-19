#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: run_library_tests.sh <library> <testcase-id> -- <command> [args...]" >&2
  exit 64
}

if (($# < 4)); then
  usage
fi

library=$1
shift

testcase_id=$1
shift

if [[ ${1:-} != "--" ]]; then
  usage
fi
shift

if (($# == 0)); then
  usage
fi

if [[ ! $testcase_id =~ ^[a-z0-9][a-z0-9-]{1,78}[a-z0-9]$ ]]; then
  echo "invalid testcase id: $testcase_id" >&2
  exit 64
fi

library_root="/validator/tests/${library}"
if [[ ! -d "$library_root" ]]; then
  echo "missing library root: $library_root" >&2
  exit 1
fi

export VALIDATOR_LIBRARY="$library"
export VALIDATOR_LIBRARY_ROOT="$library_root"
export VALIDATOR_TESTCASE_ID="$testcase_id"
export VALIDATOR_SOURCE_ROOT="$library_root/tests/tagged-port/original"
export VALIDATOR_FIXTURE_ROOT="$library_root/tests/fixtures"

exec "$@"
