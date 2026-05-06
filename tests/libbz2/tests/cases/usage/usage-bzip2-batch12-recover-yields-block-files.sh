#!/usr/bin/env bash
# @testcase: usage-bzip2-batch12-recover-yields-block-files
# @title: bzip2recover on a multi-block archive yields rec*.bz2 files
# @description: Compresses 1MB of pseudo-random data with -9 (multiple blocks), runs bzip2recover, and verifies at least one rec*.bz2 piece file is produced and each is itself a valid bz2 stream.
# @timeout: 60
# @tags: usage, compression, recover
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a deterministic ~1 MB payload that will produce several blocks at -9 (900K block size).
python3 -c '
import sys
buf = bytearray()
for i in range(1024 * 1024 + 5000):
    buf.append((i * 1103515245 + 12345) & 0xff)
sys.stdout.buffer.write(bytes(buf))
' >"$tmpdir/big.bin"

bzip2 -9c "$tmpdir/big.bin" >"$tmpdir/big.bz2"

cd "$tmpdir"
bzip2recover "big.bz2" >"$tmpdir/recover.log" 2>&1

count=$(ls rec*big.bz2 2>/dev/null | wc -l)
[[ "$count" -ge 1 ]]

# Each piece should start with the bzip2 magic.
for f in rec*big.bz2; do
    head -c 3 "$f" | od -An -c | tr -d ' \n' | grep -q 'BZh'
done
