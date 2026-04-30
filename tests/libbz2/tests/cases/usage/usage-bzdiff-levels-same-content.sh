#!/usr/bin/env bash
# @testcase: usage-bzdiff-levels-same-content
# @title: bzdiff treats different-level encodings as identical
# @description: Compresses identical content at -1 and -9 and verifies bzdiff reports no payload differences across the two encodings.
# @timeout: 240
# @tags: usage, bzip2, levels
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzdiff-levels-same-content"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Generate a payload large enough that levels 1 and 9 produce distinct
# compressed bytes, so the test is meaningful.
python3 -c 'import sys
for i in range(2048):
    sys.stdout.write(f"bzdiff level invariance line {i % 17}\n")' >"$tmpdir/in.txt"

bzip2 -1 -c "$tmpdir/in.txt" >"$tmpdir/level1.bz2"
bzip2 -9 -c "$tmpdir/in.txt" >"$tmpdir/level9.bz2"

# The compressed bytes must differ; otherwise the comparison is vacuous.
if cmp -s "$tmpdir/level1.bz2" "$tmpdir/level9.bz2"; then
  printf 'level1 and level9 compressed streams should differ but are byte-identical\n' >&2
  exit 1
fi

# bzdiff decompresses both sides and compares payloads, so it must report
# no differences and exit cleanly.
bzdiff "$tmpdir/level1.bz2" "$tmpdir/level9.bz2" >"$tmpdir/out" 2>"$tmpdir/err"
test ! -s "$tmpdir/out"
test ! -s "$tmpdir/err"
