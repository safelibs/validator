#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"ratio":1.5,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"empty":[],"child":{"label":"ok"}}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

case "$case_id" in
  usage-jshon-nested-empty-array-length)
    run_jshon "$json" -e nested -e empty -l
    grep -Fxq '0' "$tmpdir/out"
    ;;
  usage-jshon-nested-key-list)
    run_jshon "$json" -e nested -k
    validator_assert_contains "$tmpdir/out" 'child'
    validator_assert_contains "$tmpdir/out" 'empty'
    ;;
  usage-jshon-count-field)
    run_jshon "$json" -e count -u
    grep -Fxq '7' "$tmpdir/out"
    ;;
  usage-jshon-float-field)
    run_jshon "$json" -e ratio -u
    grep -Fxq '1.5' "$tmpdir/out"
    ;;
  usage-jshon-file-array-sum)
    printf '%s' "$json" >"$tmpdir/input.json"
    jshon -F "$tmpdir/input.json" -e items -a -u >"$tmpdir/out"
    awk '{sum += $1} END {print sum}' "$tmpdir/out" >"$tmpdir/sum"
    grep -Fxq '6' "$tmpdir/sum"
    ;;
  usage-jshon-array-root-type)
    printf '[{"name":"alpha"}]' | jshon -t >"$tmpdir/out"
    grep -Fxq 'array' "$tmpdir/out"
    ;;
  usage-jshon-object-array-second-type)
    run_jshon "$json" -e records -e 1 -t
    grep -Fxq 'object' "$tmpdir/out"
    ;;
  usage-jshon-escaped-slash-string)
    run_jshon '{"path":"alpha\\/beta"}' -e path -u
    grep -Fxq 'alpha\/beta' "$tmpdir/out"
    ;;
  usage-jshon-file-unicode-label)
    printf '{"label":"snowman \\u2603"}' >"$tmpdir/input.json"
    jshon -F "$tmpdir/input.json" -e label -u >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'snowman'
    ;;
  usage-jshon-nested-object-field)
    run_jshon "$json" -e nested -e child -e label -u
    grep -Fxq 'ok' "$tmpdir/out"
    ;;
  *)
    printf 'unknown libjansson even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
