#!/usr/bin/env bash
# @testcase: usage-bzip2-r15-bzip2-vv-bits-per-byte-numeric
# @title: bzip2 -vv reports a numeric bits/byte ratio strictly less than 8
# @description: Compresses a highly redundant 64KiB payload with "bzip2 -vv -c", captures stderr, extracts the numeric bits/byte value from the verbose output, and asserts it is a positive number strictly less than 8 (the upper bound for any valid encoding) and greater than zero — pinning that the ratio reported by -vv is well-formed numeric output, distinct from the existing vv-double-verbose case which only checks the literal "bits/byte" substring is present.
# @timeout: 60
# @tags: usage, bzip2, verbose, ratio
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 64 KiB of highly-redundant content compresses well so bits/byte is well below 8.
python3 -c '
import sys
sys.stdout.write("redundant payload row\n" * 3000)
' >"$tmpdir/in.txt"

bzip2 -vv -c "$tmpdir/in.txt" >"$tmpdir/out.bz2" 2>"$tmpdir/err"

# bzip2 -vv prints a line like "  3.456:1, 2.314 bits/byte, 71.07% saved, ..."
ratio=$(grep -oE '[0-9]+\.[0-9]+ bits/byte' "$tmpdir/err" | head -1 | awk '{print $1}')
[[ -n "$ratio" ]]

# Compare numerically: 0 < ratio < 8.
python3 -c "
import sys
v = float(sys.argv[1])
assert 0.0 < v < 8.0, v
print('bits-per-byte', v)
" "$ratio"

# Round-trip integrity sanity check.
bunzip2 -c "$tmpdir/out.bz2" >"$tmpdir/round.txt"
cmp "$tmpdir/in.txt" "$tmpdir/round.txt"
