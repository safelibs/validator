#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r17-xz-stdin-pipe-roundtrip-sha
# @title: xz | xz -d stdin pipe round-trip preserves payload SHA
# @description: Pipes a payload through xz then xz -d back-to-back and asserts the final stdout sha matches the original, exercising the streaming compression/decompression pipeline through the lzma library.
# @timeout: 60
# @tags: usage, xz, pipe, roundtrip
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.buffer.write(b'r17-pipe-sha-' * 512)" >"$tmpdir/in.txt"
original_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz -c <"$tmpdir/in.txt" | xz -d -c >"$tmpdir/round.txt"
round_sha=$(sha256sum "$tmpdir/round.txt" | awk '{print $1}')

[[ "$original_sha" == "$round_sha" ]] || {
  printf 'sha mismatch %s vs %s\n' "$original_sha" "$round_sha" >&2
  exit 1
}
