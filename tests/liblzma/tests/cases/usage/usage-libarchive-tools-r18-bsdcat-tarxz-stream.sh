#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r18-bsdcat-tarxz-stream
# @title: bsdcat decompresses an .xz file emitting the original payload bytes
# @description: Compresses a known payload to an .xz file and asserts bsdcat reproduces the exact bytes on stdout, exercising libarchive's xz decoder via the bsdcat front end.
# @timeout: 60
# @tags: usage, bsdcat, xz, stream, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.buffer.write(b'r18-bsdcat-stream-' * 200)" >"$tmpdir/in.bin"
src_sha=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')

xz -c "$tmpdir/in.bin" >"$tmpdir/in.bin.xz"
validator_require_file "$tmpdir/in.bin.xz"

bsdcat "$tmpdir/in.bin.xz" >"$tmpdir/out.bin"
dst_sha=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')

[[ "$src_sha" == "$dst_sha" ]] || {
  printf 'bsdcat output sha mismatch\n' >&2; exit 1;
}
