#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"items":[1,2,3],"nested":{"value":"ok"}}'

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

case "$case_id" in
  usage-jshon-read-field)
    run_jshon "$json" -e name -u
    validator_assert_contains "$tmpdir/out" 'demo'
    ;;
  usage-jshon-array-length)
    run_jshon "$json" -e items -l
    validator_assert_contains "$tmpdir/out" '3'
    ;;
  usage-jshon-array-values)
    run_jshon "$json" -e items -a -u
    validator_assert_contains "$tmpdir/out" '1'
    validator_assert_contains "$tmpdir/out" '3'
    ;;
  usage-jshon-object-keys)
    run_jshon "$json" -k
    validator_assert_contains "$tmpdir/out" 'nested'
    ;;
  usage-jshon-type-check)
    run_jshon "$json" -e active -t
    validator_assert_contains "$tmpdir/out" 'bool'
    ;;
  usage-jshon-nested-value)
    run_jshon "$json" -e nested -e value -u
    validator_assert_contains "$tmpdir/out" 'ok'
    ;;
  usage-jshon-file-input)
    printf '%s' "$json" >"$tmpdir/input.json"
    jshon -F "$tmpdir/input.json" -e name -u >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'demo'
    ;;
  usage-jshon-root-array-type)
    run_jshon '[1,2,3]' -t
    validator_assert_contains "$tmpdir/out" 'array'
    ;;
  usage-jshon-root-array-length)
    run_jshon '[1,2,3,4]' -l
    validator_assert_contains "$tmpdir/out" '4'
    ;;
  usage-jshon-number-field)
    run_jshon "$json" -e count -u
    validator_assert_contains "$tmpdir/out" '7'
    ;;
  *)
    printf 'unknown libjansson usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
