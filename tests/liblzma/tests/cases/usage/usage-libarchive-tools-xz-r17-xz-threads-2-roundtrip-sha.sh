#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r17-xz-threads-2-roundtrip-sha
# @title: xz --threads=2 round-trip yields a byte-identical decompressed payload
# @description: Compresses a small payload with xz --threads=2, decompresses with xz -d, and asserts the SHA-256 of the round-tripped output matches the original — pinning that multi-threaded compression preserves payload bytes.
# @timeout: 60
# @tags: usage, xz, threads, roundtrip
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.buffer.write(b'r17-threads-2-' + (b'ab' * 4096))" >"$tmpdir/in.txt"
original_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz --threads=2 -c "$tmpdir/in.txt" >"$tmpdir/out.xz"
validator_require_file "$tmpdir/out.xz"

xz -d -c "$tmpdir/out.xz" >"$tmpdir/round.txt"
round_sha=$(sha256sum "$tmpdir/round.txt" | awk '{print $1}')

[[ "$original_sha" == "$round_sha" ]] || {
  printf 'sha mismatch: %s vs %s\n' "$original_sha" "$round_sha" >&2
  exit 1
}
