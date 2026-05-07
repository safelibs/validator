#!/usr/bin/env bash
# @testcase: usage-bzip2-r12-bzgrep-h-no-prefix
# @title: bzgrep -h suppresses filename prefix across two .bz2 archives
# @description: Builds two .bz2 archives both containing a matching line and verifies that "bzgrep -h pattern file1.bz2 file2.bz2" emits the matched lines without the filename prefix that bzgrep would otherwise prepend in multi-file mode.
# @timeout: 60
# @tags: usage, bzgrep, no-filename
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'apple\nbanana\n' >"$tmpdir/a.txt"
printf 'banana\ncherry\n' >"$tmpdir/b.txt"
bzip2 "$tmpdir/a.txt" "$tmpdir/b.txt"

bzgrep -h 'banana' "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/out.txt"

# Two matches, neither prefixed by a filename.
[[ "$(wc -l <"$tmpdir/out.txt")" == "2" ]]
! grep -F ':' "$tmpdir/out.txt" >/dev/null
grep -Fxq 'banana' "$tmpdir/out.txt"
