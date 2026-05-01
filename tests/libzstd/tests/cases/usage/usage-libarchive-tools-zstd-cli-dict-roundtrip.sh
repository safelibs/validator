#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-dict-roundtrip
# @title: zstd CLI -D dictionary-based round-trip
# @description: Trains a zstd dictionary from a sample corpus then compresses and decompresses an unseen but similar payload using -D <dict>, asserting the dict-compressed frame requires the same dictionary at decode time and that the decoded bytes match the original input byte-for-byte.
# @timeout: 240
# @tags: usage, archive, zstd, cli, dictionary
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
    b"protocol header version 1\n",
    b"client connected with id\n",
    b"server replied with status ok\n",
    b"transferred bytes recorded\n",
    b"session closed normally\n",
]
for i in range(256):
    body = phrases[i % len(phrases)] * (3 + (i % 9))
    with open(os.path.join(out, f"s{i:03d}.log"), "wb") as fh:
        fh.write(body)
PY

dict="$tmpdir/dict.bin"
zstd -q --train "$samples"/*.log -o "$dict"
validator_require_file "$dict"

src="$tmpdir/payload.log"
python3 -c 'import sys
sys.stdout.buffer.write((b"protocol header version 1\nclient connected with id\nserver replied with status ok\n") * 1024)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q -D "$dict" -o "$tmpdir/out.zst" "$src"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -dq -D "$dict" -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
cmp "$src" "$tmpdir/decoded.bin"

dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
