#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r21-bsdtar-large-file-roundtrip-sha256
# @title: bsdtar tar.zst roundtrips a 4 MiB random payload preserving size and sha256
# @description: Creates a 4 MiB random-byte file, archives it as tar.zst, extracts it, and asserts both the file size and the SHA-256 match the original — pinning libarchive's zstd integrity for non-trivial sized payloads on Ubuntu 24.04.
# @timeout: 180
# @tags: usage, archive, bsdtar, zstd, large, sha256, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src=$tmpdir/src
mkdir -p "$src"
# Write a 4 MiB random payload deterministically.
python3 - "$src/big.bin" <<'PY'
import sys, random
random.seed(424242)
size = 4 * 1024 * 1024
with open(sys.argv[1], 'wb') as f:
    f.write(bytes(random.randrange(256) for _ in range(size)))
PY
expected_size=$(stat -c '%s' "$src/big.bin")
expected_sha=$(sha256sum "$src/big.bin" | awk '{print $1}')

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir" src

out=$tmpdir/out
mkdir -p "$out"
bsdtar --zstd -xf "$tmpdir/a.tar.zst" -C "$out"

actual_size=$(stat -c '%s' "$out/src/big.bin")
actual_sha=$(sha256sum "$out/src/big.bin" | awk '{print $1}')
[[ "$expected_size" == "$actual_size" ]] || { printf 'size mismatch: expected %s got %s\n' "$expected_size" "$actual_size" >&2; exit 1; }
[[ "$expected_sha" == "$actual_sha" ]] || { printf 'sha mismatch: expected %s got %s\n' "$expected_sha" "$actual_sha" >&2; exit 1; }
