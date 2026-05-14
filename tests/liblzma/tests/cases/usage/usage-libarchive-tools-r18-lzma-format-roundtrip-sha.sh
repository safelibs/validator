#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r18-lzma-format-roundtrip-sha
# @title: xz --format=lzma legacy stream round-trips to a byte-identical payload
# @description: Compresses a payload with xz --format=lzma, decompresses back via xz -d --format=lzma, and asserts the round-tripped SHA-256 matches the source, exercising the legacy .lzma container path through liblzma.
# @timeout: 60
# @tags: usage, xz, lzma, format, roundtrip, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.buffer.write(b'r18-lzma-format-' + (b'cd' * 2048))" >"$tmpdir/in.bin"
src_sha=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')

xz --format=lzma -c "$tmpdir/in.bin" >"$tmpdir/in.lzma"
xz -d --format=lzma -c "$tmpdir/in.lzma" >"$tmpdir/out.bin"

dst_sha=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
[[ "$src_sha" == "$dst_sha" ]] || {
  printf 'lzma format roundtrip sha mismatch\n' >&2; exit 1;
}
