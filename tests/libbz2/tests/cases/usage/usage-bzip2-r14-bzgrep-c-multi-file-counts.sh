#!/usr/bin/env bash
# @testcase: usage-bzip2-r14-bzgrep-c-multi-file-counts
# @title: bzgrep -c reports per-file counts across two .bz2 archives
# @description: Builds two .bz2 archives with different match counts for the same pattern, runs "bzgrep -c PATTERN file1.bz2 file2.bz2", and asserts the output has two lines each prefixed with the input filename and trailing colon-separated count, exercising bzgrep's multi-file -c reporting.
# @timeout: 60
# @tags: usage, bzgrep, count, multi-file
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

{
    printf 'apple one\n'
    printf 'banana\n'
    printf 'apple two\n'
    printf 'cherry\n'
    printf 'apple three\n'
} >"$tmpdir/a.txt"

{
    printf 'apple solo\n'
    printf 'date\n'
    printf 'fig\n'
} >"$tmpdir/b.txt"

bzip2 "$tmpdir/a.txt" "$tmpdir/b.txt"
[[ -f "$tmpdir/a.txt.bz2" ]]
[[ -f "$tmpdir/b.txt.bz2" ]]

bzgrep -c apple "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/counts.txt"

# Two output lines, each prefixed by its filename ending with :<count>.
[[ "$(wc -l <"$tmpdir/counts.txt")" == "2" ]]

a_count=$(awk -F: -v f="$tmpdir/a.txt.bz2" '$0 ~ f {print $NF}' "$tmpdir/counts.txt")
b_count=$(awk -F: -v f="$tmpdir/b.txt.bz2" '$0 ~ f {print $NF}' "$tmpdir/counts.txt")
test "$a_count" = "3"
test "$b_count" = "1"
