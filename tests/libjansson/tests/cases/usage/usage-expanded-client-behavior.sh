#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

case "$case_id" in
  usage-jshon-bool-false-type)
    run_jshon '{"active":false}' -e active -t
    validator_assert_contains "$tmpdir/out" 'bool'
    ;;
  usage-jshon-null-root-field-type)
    run_jshon '{"missing":null}' -e missing -t
    validator_assert_contains "$tmpdir/out" 'null'
    ;;
  usage-jshon-array-second-value)
    run_jshon '{"items":["alpha","beta","gamma"]}' -e items -e 1 -u
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-jshon-nested-array-third-value)
    run_jshon '{"outer":{"items":[10,20,30,40]}}' -e outer -e items -e 2 -u
    validator_assert_contains "$tmpdir/out" '30'
    ;;
  usage-jshon-array-first-string-type-name)
    run_jshon '["validator","beta"]' -e 0 -t
    validator_assert_contains "$tmpdir/out" 'string'
    ;;
  usage-jshon-file-object-keys)
    printf '%s' '{"alpha":1,"beta":2}' >"$tmpdir/input.json"
    jshon -F "$tmpdir/input.json" -k >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha'
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-jshon-nested-object-key-list)
    run_jshon '{"meta":{"count":2,"name":"validator"}}' -e meta -k
    validator_assert_contains "$tmpdir/out" 'count'
    validator_assert_contains "$tmpdir/out" 'name'
    ;;
  usage-jshon-escaped-newline-string)
    run_jshon '{"text":"alpha\nbeta"}' -e text -u
    validator_assert_contains "$tmpdir/out" 'alpha'
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-jshon-negative-number-value)
    run_jshon '{"delta":-12}' -e delta -u
    validator_assert_contains "$tmpdir/out" '-12'
    ;;
  usage-jshon-file-array-length)
    printf '%s' '[1,2,3,4,5]' >"$tmpdir/input.json"
    jshon -F "$tmpdir/input.json" -l >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '5'
    ;;
  *)
    printf 'unknown libjansson expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
