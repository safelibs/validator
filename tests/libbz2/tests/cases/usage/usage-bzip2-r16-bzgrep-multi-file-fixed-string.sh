#!/usr/bin/env bash
# @testcase: usage-bzip2-r16-bzgrep-multi-file-fixed-string
# @title: bzgrep -F finds a fixed string in two of three bz2 files
# @description: Compresses three distinct payloads where two contain a needle and one does not, runs bzgrep -F across all three, and asserts the output contains matches from both expected files and never from the negative one — without depending on filename prefixing.
# @timeout: 60
# @tags: usage, bzgrep, multi-file, fixed-string
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nNEEDLE-r16 hit-A\ngamma\n' >"$tmpdir/a.txt"
printf 'no match here\nplain content\n' >"$tmpdir/b.txt"
printf 'pre\nNEEDLE-r16 hit-C\npost\n' >"$tmpdir/c.txt"
for n in a b c; do bzip2 -c "$tmpdir/$n.txt" >"$tmpdir/$n.bz2"; done

bzgrep -F 'NEEDLE-r16' "$tmpdir/a.bz2" "$tmpdir/b.bz2" "$tmpdir/c.bz2" >"$tmpdir/hits"

validator_assert_contains "$tmpdir/hits" 'hit-A'
validator_assert_contains "$tmpdir/hits" 'hit-C'
! grep -F 'no match here' "$tmpdir/hits"
