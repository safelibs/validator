#!/usr/bin/env bash
# @testcase: usage-bzip2-batch12-bzdiff-three-way-equal
# @title: bzdiff between two compressed copies of the same content yields no differences
# @description: Compresses identical content into two separate .bz2 files (different filenames) and verifies bzdiff exits zero with no output (no differences).
# @timeout: 60
# @tags: usage, compression, bzdiff
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

content='line1
line2 with content
line3
'

printf '%s' "$content" >"$tmpdir/x.txt"
printf '%s' "$content" >"$tmpdir/y.txt"

bzip2 "$tmpdir/x.txt"
bzip2 "$tmpdir/y.txt"

bzdiff "$tmpdir/x.txt.bz2" "$tmpdir/y.txt.bz2" >"$tmpdir/diff.out"
size=$(stat -c '%s' "$tmpdir/diff.out")
[[ "$size" == 0 ]]
