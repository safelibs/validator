#!/usr/bin/env bash
# @testcase: usage-findutils-xargs-max-args
# @title: findutils xargs max-args batching
# @description: Pipes five tokens through xargs --max-args=2 and verifies the input is grouped into batches of two per invocation.
# @timeout: 180
# @tags: usage, findutils, batching
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-xargs-max-args"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'a\nb\nc\nd\ne\n' | xargs --max-args=2 echo >"$tmpdir/out"

line_count=$(wc -l <"$tmpdir/out")
[[ "$line_count" -eq 3 ]] || {
  printf 'expected 3 batches, got %s\n' "$line_count" >&2
  cat "$tmpdir/out" >&2
  exit 1
}

validator_assert_contains "$tmpdir/out" 'a b'
validator_assert_contains "$tmpdir/out" 'c d'
validator_assert_contains "$tmpdir/out" 'e'
