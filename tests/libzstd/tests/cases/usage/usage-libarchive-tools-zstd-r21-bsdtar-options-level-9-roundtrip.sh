#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r21-bsdtar-options-level-9-roundtrip
# @title: bsdtar --options zstd:compression-level=9 produces an archive that roundtrips with identical sha256
# @description: Creates a small tree, archives it with bsdtar --zstd --options zstd:compression-level=9, extracts it into a fresh directory and asserts the per-file SHA-256 of the extracted file equals the source SHA-256 — pinning libarchive's zstd compression-level=9 option through the bsdtar CLI on Ubuntu 24.04.
# @timeout: 120
# @tags: usage, archive, bsdtar, zstd, compression-level, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src=$tmpdir/src
mkdir -p "$src"
python3 - "$src/payload.bin" <<'PY'
import sys, random
random.seed(909)
with open(sys.argv[1], 'wb') as f:
    f.write(bytes(random.randrange(256) for _ in range(16384)))
PY
expected=$(sha256sum "$src/payload.bin" | awk '{print $1}')

bsdtar --zstd --options zstd:compression-level=9 -cf "$tmpdir/a.tar.zst" -C "$tmpdir" src

out=$tmpdir/out
mkdir -p "$out"
bsdtar --zstd -xf "$tmpdir/a.tar.zst" -C "$out"
actual=$(sha256sum "$out/src/payload.bin" | awk '{print $1}')
[[ "$expected" == "$actual" ]] || { printf 'sha mismatch: expected %s got %s\n' "$expected" "$actual" >&2; exit 1; }
