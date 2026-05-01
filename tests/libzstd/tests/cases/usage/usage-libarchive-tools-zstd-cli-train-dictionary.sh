#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-train-dictionary
# @title: zstd CLI --train builds dictionary from samples
# @description: Generates many small varied sample files, runs zstd --train on the sample directory to produce a dictionary file, and asserts the dictionary has non-zero size and starts with one of the documented zstd dictionary magic prefixes (0xEC30A437 trained or 0x28B52FFD raw content).
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
    b"alpha beta gamma delta\n",
    b"compress this segment please\n",
    b"zstd dictionary training corpus\n",
    b"the quick brown fox jumps over\n",
    b"deterministic sample text body\n",
    b"another row of payload bytes\n",
]
for i in range(256):
    body = phrases[i % len(phrases)] * (4 + (i % 11))
    with open(os.path.join(out, f"s{i:03d}.txt"), "wb") as fh:
        fh.write(body)
PY

dict="$tmpdir/dict.bin"
zstd -q --train "$samples"/*.txt -o "$dict"
validator_require_file "$dict"

size=$(stat -c %s "$dict")
test "$size" -gt 0

magic=$(od -An -N4 -tx1 "$dict" | tr -d ' \n')
case "$magic" in
  37a430ec|28b52ffd) ;;
  *)
    echo "unexpected dict magic: $magic" >&2
    exit 1
    ;;
esac
