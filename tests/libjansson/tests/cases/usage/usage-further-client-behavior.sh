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
  usage-jshon-negative-number-field)
    run_jshon '{"delta":-5}' -e delta -u
    validator_assert_contains "$tmpdir/out" '-5'
    ;;
  usage-jshon-scientific-number-field)
    run_jshon '{"ratio":1.25e3}' -e ratio -u
    validator_assert_contains "$tmpdir/out" '1250'
    ;;
  usage-jshon-empty-string-field)
    run_jshon '{"label":""}' -e label -u
    tr -d '\n' <"$tmpdir/out" >"$tmpdir/stripped"
    test ! -s "$tmpdir/stripped"
    ;;
  usage-jshon-file-root-string-value)
    printf '{"value":"plain-string"}' >"$tmpdir/input.json"
    jshon -F "$tmpdir/input.json" -e value -u >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'plain-string'
    ;;
  usage-jshon-deep-array-length)
    run_jshon '{"matrix":[[1,2],[3,4],[5,6]]}' -e matrix -l
    validator_assert_contains "$tmpdir/out" '3'
    ;;
  usage-jshon-array-object-second-key)
    run_jshon '{"rows":[{"id":1,"name":"alpha"},{"id":2,"name":"beta"}]}' -e rows -e 1 -e name -u
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-jshon-root-number-type)
    run_jshon '{"value":42}' -e value -t
    validator_assert_contains "$tmpdir/out" 'number'
    ;;
  usage-jshon-unicode-escape-string)
    run_jshon '{"word":"caf\u00e9"}' -e word -u
    od -An -tx1 "$tmpdir/out" >"$tmpdir/hex"
    validator_assert_contains "$tmpdir/hex" '63 61 66 c3 a9'
    ;;
  usage-jshon-file-nested-array-length)
    printf '{"outer":{"items":[10,20,30,40]}}' >"$tmpdir/input.json"
    jshon -F "$tmpdir/input.json" -e outer -e items -l >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '4'
    ;;
  usage-jshon-object-array-third-id)
    run_jshon '{"items":[{"id":"a"},{"id":"b"},{"id":"c"}]}' -e items -e 2 -e id -u
    validator_assert_contains "$tmpdir/out" 'c'
    ;;
  *)
    printf 'unknown libjansson further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
