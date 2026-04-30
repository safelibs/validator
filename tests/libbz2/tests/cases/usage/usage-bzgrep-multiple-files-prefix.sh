#!/usr/bin/env bash
# @testcase: usage-bzgrep-multiple-files-prefix
# @title: bzgrep prefixes matches with filename across multiple compressed inputs
# @description: Searches three compressed files at once with bzgrep and verifies each emitted match is prefixed with the originating filename, and that a non-matching file is silently skipped.
# @timeout: 180
# @tags: usage, bzgrep, multi-file
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-multiple-files-prefix"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'apple\nneedle alpha\nbanana\n' >"$tmpdir/a.txt"
printf 'cherry\ndate\nfig\n' >"$tmpdir/b.txt"
printf 'kiwi\nneedle gamma\nlemon\nneedle delta\n' >"$tmpdir/c.txt"

bzip2 -zk "$tmpdir/a.txt"
bzip2 -zk "$tmpdir/b.txt"
bzip2 -zk "$tmpdir/c.txt"

# bzgrep returns the worst per-file grep exit code; b.txt.bz2 has no match
# so grep exits 1 there and bzgrep propagates that 1. We treat 1 (no match
# in some files) as expected and only fail on >=2 (real errors).
set +e
( cd "$tmpdir" && bzgrep needle a.txt.bz2 b.txt.bz2 c.txt.bz2 ) >"$tmpdir/out"
rc=$?
set -e
if (( rc >= 2 )); then
  printf 'bzgrep failed with exit %s\n' "$rc" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/out" 'a.txt.bz2:needle alpha'
validator_assert_contains "$tmpdir/out" 'c.txt.bz2:needle gamma'
validator_assert_contains "$tmpdir/out" 'c.txt.bz2:needle delta'

# b.txt.bz2 has no matches; its filename must not appear at all.
if grep -Fq 'b.txt.bz2' "$tmpdir/out"; then
  printf 'non-matching file leaked into output\n' >&2
  sed -n '1,20p' "$tmpdir/out" >&2
  exit 1
fi

line_count=$(wc -l <"$tmpdir/out")
[[ "$line_count" -eq 3 ]] || {
  printf 'expected 3 match lines, got %s\n' "$line_count" >&2
  sed -n '1,20p' "$tmpdir/out" >&2
  exit 1
}
