#!/usr/bin/env bash
# @testcase: usage-bzgrep-r11-files-with-matches-flag
# @title: bzgrep -l prints filenames of matching archives only
# @description: Builds two .bz2 archives where only one contains the search pattern and verifies bzgrep -l prints just the matching archive's filename, omits the non-matching archive, and writes no per-line content to stdout (bzgrep returns nonzero when at least one input has no matches, so the exit status is captured rather than checked by set -e).
# @timeout: 60
# @tags: usage, bzgrep, files-with-matches
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'apple\nbanana\ncherry\n' >"$tmpdir/has-match.txt"
printf 'pear\nplum\n' >"$tmpdir/no-match.txt"
bzip2 "$tmpdir/has-match.txt" "$tmpdir/no-match.txt"

# bzgrep -l with a mix of matching/non-matching files exits 1; capture it.
status=0
bzgrep -l 'banana' "$tmpdir/has-match.txt.bz2" "$tmpdir/no-match.txt.bz2" >"$tmpdir/out.txt" || status=$?
[[ "$status" == "1" ]]

# Output is exactly one line: the matching filename.
[[ "$(wc -l <"$tmpdir/out.txt")" == "1" ]]
grep -Fxq "$tmpdir/has-match.txt.bz2" "$tmpdir/out.txt"
! grep -Fq "no-match" "$tmpdir/out.txt"
# No payload-content lines leaked.
! grep -F 'banana' "$tmpdir/out.txt" >/dev/null
