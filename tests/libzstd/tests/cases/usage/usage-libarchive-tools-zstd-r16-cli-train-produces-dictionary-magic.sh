#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r16-cli-train-produces-dictionary-magic
# @title: zstd --train on a small sample corpus emits a dictionary whose first four bytes are the zstd dict magic
# @description: Generates a corpus of 128 small training samples, runs zstd --train to build a dictionary, and asserts the produced file exists and starts with the canonical zstd dictionary magic 0x37A430EC (little-endian), without further exercising the dictionary semantics.
# @timeout: 180
# @tags: usage, archive, zstd, cli, train, dictionary
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
    b"r16 train phrase alpha\n",
    b"r16 train phrase bravo\n",
    b"r16 train phrase charlie\n",
    b"r16 train phrase delta\n",
]
for i in range(128):
    body = phrases[i % len(phrases)] * (6 + (i % 7))
    with open(os.path.join(out, f's{i:03d}.txt'), 'wb') as fh:
        fh.write(body)
PY

dict="$tmpdir/r16.dict"
zstd --train -q "$samples"/*.txt -o "$dict"
validator_require_file "$dict"

magic=$(od -An -N4 -tx1 "$dict" | tr -d ' \n')
test "$magic" = "37a430ec" || {
    printf 'expected zstd dictionary magic 37a430ec, got %s\n' "$magic" >&2
    exit 1
}
