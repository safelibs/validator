#!/usr/bin/env bash
# @testcase: usage-bzip2-r12-stdin-test-corrupt-fails
# @title: bzip2 -t on a corrupted stream from stdin exits nonzero
# @description: Compresses a payload, flips a byte deep in the data block (offset 30) to corrupt it, and runs "bzip2 -t" with stdin redirected from the damaged file. The integrity check must exit nonzero.
# @timeout: 60
# @tags: usage, integrity, corrupt, stdin
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 200); do
    printf 'corrupt-test row %03d alpha beta gamma\n' "$i"
done >"$tmpdir/in.txt"

bzip2 "$tmpdir/in.txt"
[[ -f "$tmpdir/in.txt.bz2" ]]

# Flip a byte at offset 30 (well into the compressed block, not the magic).
python3 -c '
import sys
src = open(sys.argv[1], "rb").read()
buf = bytearray(src)
buf[30] ^= 0xff
open(sys.argv[1], "wb").write(bytes(buf))
' "$tmpdir/in.txt.bz2"

status=0
bzip2 -t <"$tmpdir/in.txt.bz2" >"$tmpdir/out.txt" 2>"$tmpdir/err.txt" || status=$?

[[ "$status" != "0" ]]
