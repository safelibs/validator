#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r21-bsdtar-level-1-vs-19-size-monotonic
# @title: bsdtar --zstd at zstd:compression-level=19 produces an archive no larger than at level=1 for a compressible payload
# @description: Builds a highly compressible 64 KiB payload of repeating bytes, archives it via bsdtar --zstd at zstd:compression-level=1 and zstd:compression-level=19, and asserts the level-19 archive is less than or equal to the level-1 archive in size — pinning libarchive's zstd level monotonicity on compressible input on Ubuntu 24.04.
# @timeout: 120
# @tags: usage, archive, bsdtar, zstd, level, monotonic, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src=$tmpdir/src
mkdir -p "$src"
python3 - "$src/payload.bin" <<'PY'
import sys
# Highly compressible: 64 KiB of a repeating 16-byte pattern.
pattern = b'libzstd-r21-pat!'  # 16 bytes
data = pattern * (65536 // 16)
with open(sys.argv[1], 'wb') as f:
    f.write(data)
PY

bsdtar --zstd --options zstd:compression-level=1 -cf "$tmpdir/l1.tar.zst" -C "$tmpdir" src
bsdtar --zstd --options zstd:compression-level=19 -cf "$tmpdir/l19.tar.zst" -C "$tmpdir" src

s_lo=$(stat -c '%s' "$tmpdir/l19.tar.zst")
s_hi=$(stat -c '%s' "$tmpdir/l1.tar.zst")
[[ "$s_lo" -le "$s_hi" ]] || { printf 'expected level-19 (%s) <= level-1 (%s)\n' "$s_lo" "$s_hi" >&2; exit 1; }
