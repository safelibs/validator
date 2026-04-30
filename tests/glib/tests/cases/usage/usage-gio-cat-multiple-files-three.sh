#!/usr/bin/env bash
# @testcase: usage-gio-cat-multiple-files-three
# @title: gio cat concatenates three files in order
# @description: Concatenates three text files with gio cat and verifies all three payloads appear in the merged output in argument order.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-cat-multiple-files-three"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha-block\n' >"$tmpdir/a.txt"
printf 'beta-block\n' >"$tmpdir/b.txt"
printf 'gamma-block\n' >"$tmpdir/c.txt"

gio cat "$tmpdir/a.txt" "$tmpdir/b.txt" "$tmpdir/c.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'alpha-block'
validator_assert_contains "$tmpdir/out" 'beta-block'
validator_assert_contains "$tmpdir/out" 'gamma-block'

# Order matters: alpha must precede beta which must precede gamma.
order=$(grep -nE '(alpha|beta|gamma)-block' "$tmpdir/out" | cut -d: -f1 | tr '\n' ' ')
read -r line_a line_b line_c <<<"$order"
[[ -n "$line_a" && -n "$line_b" && -n "$line_c" ]] || {
  printf 'expected three matching lines, got: %s\n' "$order" >&2
  exit 1
}
if (( line_a >= line_b )) || (( line_b >= line_c )); then
  printf 'expected ascending order, got: %s\n' "$order" >&2
  exit 1
fi
