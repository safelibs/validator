#!/usr/bin/env bash
# @testcase: usage-bzip2-sha256-roundtrip-binary
# @title: bzip2 round-trip preserves binary sha256
# @description: Compresses random binary input and verifies the decompressed sha256 matches the original byte-for-byte.
# @timeout: 180
# @tags: usage, compression, binary
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Reproducible binary input that covers the full 0x00..0xff byte range.
python3 -c '
import sys
data = bytes(((i * 31 + 7) & 0xff) for i in range(64 * 1024))
sys.stdout.buffer.write(data)
' >"$tmpdir/in.bin"

original_sha=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')
bzip2 -c "$tmpdir/in.bin" >"$tmpdir/in.bin.bz2"
bzip2 -dc "$tmpdir/in.bin.bz2" >"$tmpdir/out.bin"

roundtrip_sha=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
if [[ "$original_sha" != "$roundtrip_sha" ]]; then
  printf 'sha256 mismatch: original=%s decoded=%s\n' "$original_sha" "$roundtrip_sha" >&2
  exit 1
fi
cmp "$tmpdir/in.bin" "$tmpdir/out.bin"
