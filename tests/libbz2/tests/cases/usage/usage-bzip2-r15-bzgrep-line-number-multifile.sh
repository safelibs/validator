#!/usr/bin/env bash
# @testcase: usage-bzip2-r15-bzgrep-line-number-multifile
# @title: bzgrep -n with two .bz2 files prefixes filename and line number per match
# @description: Builds two .bz2 archives each containing the matching pattern at distinct line offsets, runs "bzgrep -n PATTERN file1.bz2 file2.bz2" with both files as positional arguments, and asserts the output contains a "<filename>:<lineno>:" prefix for each file's match — exercising the combined multi-file plus -n reporting (distinct from the single-file -n case).
# @timeout: 60
# @tags: usage, bzgrep, line-number, multi-file
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

{
    printf 'first line\n'
    printf 'apple match here\n'
    printf 'third line\n'
} >"$tmpdir/a.txt"

{
    printf 'one\n'
    printf 'two\n'
    printf 'three\n'
    printf 'apple here on line 4\n'
    printf 'tail\n'
} >"$tmpdir/b.txt"

bzip2 "$tmpdir/a.txt" "$tmpdir/b.txt"

bzgrep -n apple "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/out.txt"

# Each matching line must be prefixed by <filename>:<lineno>:
grep -Fq "$tmpdir/a.txt.bz2:2:" "$tmpdir/out.txt"
grep -Fq "$tmpdir/b.txt.bz2:4:" "$tmpdir/out.txt"
[[ "$(wc -l <"$tmpdir/out.txt")" == "2" ]]
