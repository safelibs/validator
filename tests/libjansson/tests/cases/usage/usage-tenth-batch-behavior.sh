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
  usage-jshon-bool-true-type)
    run_jshon '{"active":true}' -e active -t
    validator_assert_contains "$tmpdir/out" 'bool'
    ;;
  usage-jshon-object-type-root)
    run_jshon '{"alpha":1}' -t
    validator_assert_contains "$tmpdir/out" 'object'
    ;;
  usage-jshon-array-type-root)
    run_jshon '[1, 2, 3]' -t
    validator_assert_contains "$tmpdir/out" 'array'
    ;;
  usage-jshon-array-length-root)
    run_jshon '[10, 20, 30, 40, 50, 60]' -l
    validator_assert_contains "$tmpdir/out" '6'
    ;;
  usage-jshon-object-length-root)
    run_jshon '{"a":1,"b":2,"c":3,"d":4}' -l
    validator_assert_contains "$tmpdir/out" '4'
    ;;
  usage-jshon-zero-number-value)
    run_jshon '{"value":0}' -e value -u
    validator_assert_contains "$tmpdir/out" '0'
    ;;
  usage-jshon-fractional-number-value)
    run_jshon '{"ratio":0.25}' -e ratio -u
    validator_assert_contains "$tmpdir/out" '0.25'
    ;;
  usage-jshon-array-last-element)
    run_jshon '{"items":["alpha","beta","gamma","delta"]}' -e items -e 3 -u
    validator_assert_contains "$tmpdir/out" 'delta'
    ;;
  usage-jshon-file-nested-object-key)
    printf '{"outer":{"inner":{"label":"validator"}}}' >"$tmpdir/input.json"
    jshon -F "$tmpdir/input.json" -e outer -e inner -e label -u >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'validator'
    ;;
  usage-jshon-string-with-spaces-field)
    run_jshon '{"phrase":"hello world"}' -e phrase -u
    validator_assert_contains "$tmpdir/out" 'hello world'
    ;;
  *)
    printf 'unknown libjansson tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
