#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"active":true,"disabled":false,"empty":null,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"value":"ok","label":"hello world"}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

case "$case_id" in
  usage-jshon-root-object-type)
    run_jshon "$json" -t
    validator_assert_contains "$tmpdir/out" 'object'
    ;;
  usage-jshon-false-field)
    run_jshon "$json" -e disabled -u
    validator_assert_contains "$tmpdir/out" 'false'
    ;;
  usage-jshon-null-type)
    run_jshon "$json" -e empty -t
    validator_assert_contains "$tmpdir/out" 'null'
    ;;
  usage-jshon-array-index)
    run_jshon "$json" -e items -e 1 -u
    validator_assert_contains "$tmpdir/out" '2'
    ;;
  usage-jshon-nested-array-value)
    run_jshon "$json" -e records -e 1 -e name -u
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-jshon-object-length)
    run_jshon "$json" -l
    validator_assert_contains "$tmpdir/out" '8'
    ;;
  usage-jshon-string-with-space)
    run_jshon "$json" -e nested -e label -u
    validator_assert_contains "$tmpdir/out" 'hello world'
    ;;
  usage-jshon-number-array-sum)
    run_jshon "$json" -e items -a -u
    awk '{sum += $1} END {print "sum=" sum}' "$tmpdir/out" >"$tmpdir/sum"
    validator_assert_contains "$tmpdir/sum" 'sum=6'
    ;;
  usage-jshon-file-root-array)
    printf '[{"id":1},{"id":2},{"id":3}]' >"$tmpdir/input.json"
    jshon -F "$tmpdir/input.json" -l >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '3'
    ;;
  usage-jshon-deep-object-keys)
    run_jshon "$json" -e nested -k
    validator_assert_contains "$tmpdir/out" 'label'
    validator_assert_contains "$tmpdir/out" 'value'
    ;;
  usage-jshon-true-field)
    run_jshon "$json" -e active -u
    validator_assert_contains "$tmpdir/out" 'true'
    ;;
  usage-jshon-nested-type)
    run_jshon "$json" -e nested -t
    validator_assert_contains "$tmpdir/out" 'object'
    ;;
  usage-jshon-records-length)
    run_jshon "$json" -e records -l
    validator_assert_contains "$tmpdir/out" '2'
    ;;
  usage-jshon-first-record-name)
    run_jshon "$json" -e records -e 0 -e name -u
    validator_assert_contains "$tmpdir/out" 'alpha'
    ;;
  usage-jshon-root-key-list)
    run_jshon "$json" -k
    validator_assert_contains "$tmpdir/out" 'active'
    validator_assert_contains "$tmpdir/out" 'name'
    ;;
  usage-jshon-file-root-object)
    printf '%s' "$json" >"$tmpdir/input.json"
    jshon -F "$tmpdir/input.json" -t >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'object'
    ;;
  usage-jshon-file-nested-label)
    printf '%s' "$json" >"$tmpdir/input.json"
    jshon -F "$tmpdir/input.json" -e nested -e label -u >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'hello world'
    ;;
  usage-jshon-third-array-value)
    run_jshon "$json" -e items -e 2 -u
    validator_assert_contains "$tmpdir/out" '3'
    ;;
  usage-jshon-name-field)
    run_jshon "$json" -e name -u
    validator_assert_contains "$tmpdir/out" 'demo'
    ;;
  usage-jshon-nested-object-length)
    run_jshon "$json" -e nested -l
    validator_assert_contains "$tmpdir/out" '2'
    ;;
  *)
    printf 'unknown libjansson extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
