#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r19-xzcat-decompresses-xz
# @title: xzcat decompresses an .xz file emitting the original payload bytes
# @description: Compresses a 2 KiB payload to .xz with xz, then runs xzcat against it and asserts the SHA-256 of stdout equals the source SHA, pinning xzcat's pass-through decompression behavior.
# @timeout: 60
# @tags: usage, xzcat, decompress, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.buffer.write(b'r19-xzcat-payload-' * 100)" >"$tmpdir/in.bin"
src_sha=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')

xz -c "$tmpdir/in.bin" >"$tmpdir/in.xz"
xzcat "$tmpdir/in.xz" >"$tmpdir/out.bin"

dst_sha=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
[[ "$src_sha" == "$dst_sha" ]] || {
  printf 'xzcat sha mismatch\n' >&2; exit 1;
}
