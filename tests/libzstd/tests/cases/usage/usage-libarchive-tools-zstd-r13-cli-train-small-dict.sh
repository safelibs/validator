#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r13-cli-train-small-dict
# @title: zstd CLI --train --maxdict=8192 caps the trained dictionary at the requested ceiling
# @description: Generates 256 small varied sample files, runs zstd --train --maxdict=8192 to produce a dictionary file, asserts the dictionary file exists, has non-zero size at or below the 8192 byte cap, and starts with a valid zstd dictionary or raw-content magic prefix.
# @timeout: 300
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
    b"r13 alpha beta gamma delta\n",
    b"r13 compress this segment please\n",
    b"r13 zstd dictionary training\n",
    b"r13 the quick brown fox jumps over\n",
    b"r13 deterministic sample text body\n",
    b"r13 another row of payload bytes\n",
]
for i in range(256):
    body = phrases[i % len(phrases)] * (4 + (i % 11))
    with open(os.path.join(out, f"s{i:03d}.txt"), "wb") as fh:
        fh.write(body)
PY

dict="$tmpdir/dict.bin"
zstd -q --train --maxdict=8192 "$samples"/*.txt -o "$dict"
validator_require_file "$dict"

size=$(stat -c %s "$dict")
test "$size" -gt 0
test "$size" -le 8192 || {
    printf 'expected dict size <= 8192, got %d\n' "$size" >&2
    exit 1
}

magic=$(od -An -N4 -tx1 "$dict" | tr -d ' \n')
case "$magic" in
  37a430ec|28b52ffd) ;;
  *)
    echo "unexpected dict magic: $magic" >&2
    exit 1
    ;;
esac
