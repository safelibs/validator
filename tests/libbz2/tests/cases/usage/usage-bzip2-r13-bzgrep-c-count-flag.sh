#!/usr/bin/env bash
# @testcase: usage-bzip2-r13-bzgrep-c-count-flag
# @title: bzgrep -c reports a per-file matching line count
# @description: Builds a .bz2 file with a known number of lines containing the pattern and runs "bzgrep -c PATTERN file.bz2", asserting the printed integer equals the expected match count.
# @timeout: 60
# @tags: usage, bzgrep, count
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

{
  printf 'apple\nbanana\napple pie\nfig\napple sauce\ncherry\napple\n'
} >"$tmpdir/data.txt"
bzip2 "$tmpdir/data.txt"
[[ -f "$tmpdir/data.txt.bz2" ]]

count=$(bzgrep -c apple "$tmpdir/data.txt.bz2")
test "$count" = "4"
