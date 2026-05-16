#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r21-bsdtar-options-long-25-roundtrip
# @title: bsdtar --options zstd:long=25 archive roundtrips and preserves the payload sha256
# @description: Creates a small payload, archives it with bsdtar --zstd --options zstd:long=25 (long-range mode), extracts it and asserts the SHA-256 matches the source — pinning libarchive's zstd:long option threading through the bsdtar CLI on Ubuntu 24.04.
# @timeout: 120
# @tags: usage, archive, bsdtar, zstd, long-mode, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src=$tmpdir/src
mkdir -p "$src"
python3 - "$src/payload.bin" <<'PY'
import sys, random
random.seed(2526)
with open(sys.argv[1], 'wb') as f:
    f.write(bytes(random.randrange(256) for _ in range(32768)))
PY
expected=$(sha256sum "$src/payload.bin" | awk '{print $1}')

bsdtar --zstd --options zstd:long=25 -cf "$tmpdir/a.tar.zst" -C "$tmpdir" src

out=$tmpdir/out
mkdir -p "$out"
bsdtar --zstd -xf "$tmpdir/a.tar.zst" -C "$out"
actual=$(sha256sum "$out/src/payload.bin" | awk '{print $1}')
[[ "$expected" == "$actual" ]] || { printf 'sha mismatch: expected %s got %s\n' "$expected" "$actual" >&2; exit 1; }
