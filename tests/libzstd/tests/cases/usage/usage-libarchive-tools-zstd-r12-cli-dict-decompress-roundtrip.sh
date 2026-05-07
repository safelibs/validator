#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r12-cli-dict-decompress-roundtrip
# @title: zstd -D round-trip uses the trained dictionary on encode and decode
# @description: Trains a small dictionary from synthetic samples, compresses an unrelated input with -D dict, and decodes it with -D dict to confirm the dictionary-bound encoder and decoder reconstruct the input byte-for-byte.
# @timeout: 240
# @tags: usage, zstd, cli, dictionary
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
    b"r12 dict-roundtrip sample alpha line\n",
    b"r12 dict-roundtrip sample bravo line\n",
    b"r12 dict-roundtrip sample charlie line\n",
    b"r12 dict-roundtrip sample delta line\n",
]
for i in range(256):
    body = phrases[i % len(phrases)] * (3 + (i % 7))
    with open(os.path.join(out, f"s{i:03d}.txt"), "wb") as fh:
        fh.write(body)
PY

dict="$tmpdir/dict.bin"
zstd -q --train "$samples"/*.txt -o "$dict"
validator_require_file "$dict"

# Build payload using the same phrase distribution as the corpus.
python3 - "$tmpdir/payload.txt" <<'PY'
import sys
path = sys.argv[1]
phrases = [
    b"r12 dict-roundtrip sample alpha line\n",
    b"r12 dict-roundtrip sample bravo line\n",
    b"r12 dict-roundtrip sample charlie line\n",
    b"r12 dict-roundtrip sample delta line\n",
]
with open(path, 'wb') as fh:
    for i in range(200):
        fh.write(phrases[i % 4])
PY

zstd -q -D "$dict" "$tmpdir/payload.txt" -o "$tmpdir/payload.txt.zst"
validator_require_file "$tmpdir/payload.txt.zst"

zstd -dq -D "$dict" "$tmpdir/payload.txt.zst" -o "$tmpdir/decoded.txt"
cmp "$tmpdir/payload.txt" "$tmpdir/decoded.txt"
