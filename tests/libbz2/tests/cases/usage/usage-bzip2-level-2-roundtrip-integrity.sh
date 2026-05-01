#!/usr/bin/env bash
# @testcase: usage-bzip2-level-2-roundtrip-integrity
# @title: bzip2 -2 roundtrip integrity
# @description: Compresses a 200KB structured payload at block level 2 and verifies bzip2 -t accepts it and bunzip2 -c reproduces the bytes exactly.
# @timeout: 120
# @tags: usage, bzip2, levels
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-level-2-roundtrip-integrity"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
for i in range(8000):
    sys.stdout.write("level2 line index %05d alpha beta gamma\n" % i)
' >"$tmpdir/input.txt"

bzip2 -2 -k "$tmpdir/input.txt"
validator_require_file "$tmpdir/input.txt.bz2"
bzip2 -t "$tmpdir/input.txt.bz2"
bunzip2 -c "$tmpdir/input.txt.bz2" >"$tmpdir/decoded.txt"
cmp "$tmpdir/input.txt" "$tmpdir/decoded.txt"
