#!/usr/bin/env bash
# @testcase: usage-sed-hold-space-swap
# @title: sed hold-space line swap
# @description: Swaps two adjacent lines using the sed hold space with h and G and verifies the reordered output.
# @timeout: 180
# @tags: usage, sed, text
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-hold-space-swap"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first\nsecond\n' >"$tmpdir/in.txt"
sed -n '1h; 2{ G; p }' "$tmpdir/in.txt" >"$tmpdir/out"

# Output must be exactly "second\nfirst\n".
expected=$(printf 'second\nfirst\n')
actual=$(cat "$tmpdir/out")
if [[ "$actual" != "$expected" ]]; then
  printf 'unexpected hold-space output:\n%s\n' "$actual" >&2
  exit 1
fi
