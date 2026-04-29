#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

json='{"meta":{"enabled":true,"missing":null,"hyphen-key":"dash"},"matrix":[[1,2],[3,4]],"records":[{"name":"alpha","score":1.5},{"name":"beta","score":2.5}],"text":"a/b c","number":-12.5}'

case "$case_id" in
  usage-jshon-batch11-nested-bool-unstring)
    run_jshon "$json" -e meta -e enabled -u
    validator_assert_contains "$tmpdir/out" 'true'
    ;;
  usage-jshon-batch11-nested-null-type)
    run_jshon "$json" -e meta -e missing -t
    validator_assert_contains "$tmpdir/out" 'null'
    ;;
  usage-jshon-batch11-slash-string)
    run_jshon "$json" -e text -u
    validator_assert_contains "$tmpdir/out" 'a/b c'
    ;;
  usage-jshon-batch11-array-object-second-name)
    run_jshon "$json" -e records -e 1 -e name -u
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-jshon-batch11-file-nested-number)
    printf '%s' "$json" >"$tmpdir/input.json"
    jshon -F "$tmpdir/input.json" -e records -e 0 -e score -u >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '1.5'
    ;;
  usage-jshon-batch11-root-array-object-field)
    run_jshon '[{"id":"first"},{"id":"second"}]' -e 1 -e id -u
    validator_assert_contains "$tmpdir/out" 'second'
    ;;
  usage-jshon-batch11-hyphen-key-field)
    run_jshon "$json" -e meta -e hyphen-key -u
    validator_assert_contains "$tmpdir/out" 'dash'
    ;;
  usage-jshon-batch11-negative-number)
    run_jshon "$json" -e number -u
    validator_assert_contains "$tmpdir/out" '-12.5'
    ;;
  usage-jshon-batch11-matrix-row-length)
    run_jshon "$json" -e matrix -e 1 -l
    validator_assert_contains "$tmpdir/out" '2'
    ;;
  usage-jshon-batch11-matrix-value)
    run_jshon "$json" -e matrix -e 1 -e 0 -u
    validator_assert_contains "$tmpdir/out" '3'
    ;;
  *)
    printf 'unknown libjansson eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
