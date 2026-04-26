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
  usage-jshon-root-bool-type)
    if printf 'true' | jshon -t >"$tmpdir/out" 2>&1; then
      printf 'jshon unexpectedly accepted a root boolean document\n' >&2
      exit 1
    fi
    validator_assert_contains "$tmpdir/out" "'[' or '{' expected"
    validator_assert_contains "$tmpdir/out" "near 'true'"
    ;;
  usage-jshon-root-null-type)
    if printf 'null' | jshon -t >"$tmpdir/out" 2>&1; then
      printf 'jshon unexpectedly accepted a root null document\n' >&2
      exit 1
    fi
    validator_assert_contains "$tmpdir/out" "'[' or '{' expected"
    validator_assert_contains "$tmpdir/out" "near 'null'"
    ;;
  usage-jshon-empty-array-length)
    run_jshon '[]' -l
    grep -Fxq '0' "$tmpdir/out"
    ;;
  usage-jshon-empty-object-length)
    run_jshon '{}' -l
    grep -Fxq '0' "$tmpdir/out"
    ;;
  usage-jshon-root-string-type)
    if printf '"validator"' | jshon -t >"$tmpdir/out" 2>&1; then
      printf 'jshon unexpectedly accepted a root string document\n' >&2
      exit 1
    fi
    validator_assert_contains "$tmpdir/out" "'[' or '{' expected"
    validator_assert_contains "$tmpdir/out" "near '\"validator\"'"
    ;;
  usage-jshon-unicode-string)
    run_jshon '{"label":"snowman \\u2603"}' -e label -u
    validator_assert_contains "$tmpdir/out" 'snowman'
    ;;
  usage-jshon-escaped-string)
    run_jshon '{"line":"alpha\\nbeta"}' -e line -u
    validator_assert_contains "$tmpdir/out" 'alpha'
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-jshon-file-empty-object)
    printf '{}' >"$tmpdir/input.json"
    jshon -F "$tmpdir/input.json" -t >"$tmpdir/out"
    grep -Fxq 'object' "$tmpdir/out"
    ;;
  usage-jshon-file-array-object-key)
    printf '[{"name":"alpha"},{"name":"beta"}]' >"$tmpdir/input.json"
    jshon -F "$tmpdir/input.json" -e 1 -e name -u >"$tmpdir/out"
    grep -Fxq 'beta' "$tmpdir/out"
    ;;
  usage-jshon-boolean-array-values)
    run_jshon '[true,false,true]' -a -u
    validator_assert_contains "$tmpdir/out" 'true'
    validator_assert_contains "$tmpdir/out" 'false'
    ;;
  *)
    printf 'unknown libjansson additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
