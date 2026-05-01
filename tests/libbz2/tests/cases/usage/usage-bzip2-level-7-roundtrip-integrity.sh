#!/usr/bin/env bash
# @testcase: usage-bzip2-level-7-roundtrip-integrity
# @title: bzip2 -7 roundtrip integrity
# @description: Compresses a deterministic payload at block level 7 and verifies bzip2 -t accepts the file and the round-tripped bytes match the original.
# @timeout: 120
# @tags: usage, bzip2, levels
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-level-7-roundtrip-integrity"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
for i in range(12000):
    sys.stdout.write("level7 row %06d compressible token token token\n" % i)
' >"$tmpdir/payload.txt"

bzip2 -7 -k "$tmpdir/payload.txt"
validator_require_file "$tmpdir/payload.txt.bz2"
bzip2 -t "$tmpdir/payload.txt.bz2"
bunzip2 -c "$tmpdir/payload.txt.bz2" >"$tmpdir/restored.txt"
cmp "$tmpdir/payload.txt" "$tmpdir/restored.txt"
