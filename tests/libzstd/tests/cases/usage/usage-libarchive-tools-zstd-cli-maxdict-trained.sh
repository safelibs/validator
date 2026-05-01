#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-maxdict-trained
# @title: zstd CLI --maxdict caps the trained dictionary
# @description: Generates a varied text corpus and runs zstd --train twice with --maxdict=4096 and --maxdict=65536, verifies both dictionaries are produced with non-zero size, asserts the small dictionary's byte size respects the 4096 cap, and that the large-cap run is at least as big as the small-cap run so the limit is observed.
# @timeout: 300
# @tags: usage, archive, zstd, cli, dictionary, maxdict
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$tmpdir/samples"
mkdir -p "$samples"
python3 - "$samples" <<'PY'
import os
import random
import sys
out = sys.argv[1]
words = [
    b"alpha", b"beta", b"gamma", b"delta", b"epsilon", b"zeta",
    b"eta", b"theta", b"iota", b"kappa", b"lambda", b"mu",
    b"compress", b"decompress", b"dictionary", b"training", b"corpus",
    b"validator", b"libzstd", b"frame", b"window", b"checksum",
]
for i in range(1024):
    rng = random.Random(i)
    body = b" ".join(rng.choice(words) for _ in range(200)) + b"\n"
    with open(os.path.join(out, f"s{i:04d}.txt"), "wb") as fh:
        fh.write(body)
PY

zstd -q --maxdict=4096 --train "$samples"/*.txt -o "$tmpdir/dict-4k.bin"
zstd -q --maxdict=65536 --train "$samples"/*.txt -o "$tmpdir/dict-64k.bin"
validator_require_file "$tmpdir/dict-4k.bin"
validator_require_file "$tmpdir/dict-64k.bin"

size_4k=$(stat -c %s "$tmpdir/dict-4k.bin")
size_64k=$(stat -c %s "$tmpdir/dict-64k.bin")
test "$size_4k" -gt 0
test "$size_64k" -gt 0
# Small-cap dictionary must respect the 4096-byte limit.
test "$size_4k" -le 4096
# A larger cap must allow at least as large a dictionary on the same corpus.
test "$size_64k" -ge "$size_4k"

# Both files must carry one of the documented zstd dictionary magics.
for f in "$tmpdir/dict-4k.bin" "$tmpdir/dict-64k.bin"; do
  m=$(od -An -N4 -tx1 "$f" | tr -d ' \n')
  case "$m" in
    37a430ec|28b52ffd) ;;
    *)
      echo "unexpected dict magic for $f: $m" >&2
      exit 1
      ;;
  esac
done
