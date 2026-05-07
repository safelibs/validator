#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r15-cli-train-fastcover-flag
# @title: zstd --train-fastcover trains a dictionary that round-trips a sample payload
# @description: Generates a corpus of small training samples, runs zstd --train-fastcover=k=32 to build a fastcover-trained dictionary, asserts the produced file is a Zstandard dictionary, then compresses and decompresses a payload with -D against it and confirms a byte-for-byte SHA-256 round-trip.
# @timeout: 240
# @tags: usage, archive, zstd, cli, dictionary, train-fastcover
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$tmpdir/samples"
mkdir -p "$samples"
python3 - "$samples" <<'PY'
import os, sys
out = sys.argv[1]
phrases = [
    b"r15 fastcover alpha\n",
    b"r15 fastcover bravo\n",
    b"r15 fastcover charlie\n",
    b"r15 fastcover delta\n",
]
for i in range(256):
    body = phrases[i % len(phrases)] * (5 + (i % 9))
    with open(os.path.join(out, f"s{i:03d}.txt"), "wb") as fh:
        fh.write(body)
PY

dict="$tmpdir/fc.dict"
zstd --train-fastcover=k=32 -q "$samples"/*.txt -o "$dict"
validator_require_file "$dict"

# File magic for a zstd dictionary starts with 0x37A430EC (LE).
magic=$(od -An -N4 -tx1 "$dict" | tr -d ' \n')
test "$magic" = "37a430ec" || {
    printf 'expected zstd dictionary magic, got %s\n' "$magic" >&2
    exit 1
}

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r15 fastcover payload row\n" * 200)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -D "$dict" -o "$tmpdir/out.zst" "$src"
zstd -dq -D "$dict" -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
