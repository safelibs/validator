#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r19-xz-stdin-decompress-roundtrip
# @title: xz -d reads from stdin and reproduces a byte-identical payload on stdout
# @description: Compresses a 4 KiB random-looking payload with xz, then pipes the .xz bytes into xz -d and asserts the SHA-256 of the decompressed stdout matches the original, pinning the streaming-decode contract.
# @timeout: 60
# @tags: usage, xz, stdin, roundtrip, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.buffer.write(bytes((i * 37) & 0xff for i in range(4096)))" >"$tmpdir/in.bin"
src_sha=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')

xz -c "$tmpdir/in.bin" >"$tmpdir/in.xz"
xz -d <"$tmpdir/in.xz" >"$tmpdir/out.bin"

dst_sha=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
[[ "$src_sha" == "$dst_sha" ]] || {
  printf 'sha mismatch %s vs %s\n' "$src_sha" "$dst_sha" >&2; exit 1;
}
