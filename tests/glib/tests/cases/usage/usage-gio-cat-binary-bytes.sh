#!/usr/bin/env bash
# @testcase: usage-gio-cat-binary-bytes
# @title: gio cat reproduces binary bytes
# @description: Streams a small binary file containing NUL and high bytes through gio cat and verifies the byte-for-byte output equals the source via sha256.
# @timeout: 120
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-cat-binary-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a deterministic binary blob: 0x00..0xff repeated.
python3 - <<PY
import os
data = bytes(range(256)) * 4
with open(os.path.join("$tmpdir", "blob.bin"), "wb") as fh:
    fh.write(data)
PY

gio cat "$tmpdir/blob.bin" >"$tmpdir/out.bin"

src_hash=$(sha256sum "$tmpdir/blob.bin" | awk '{print $1}')
dst_hash=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
[[ "$src_hash" = "$dst_hash" ]] || {
  printf 'sha256 mismatch: src=%s dst=%s\n' "$src_hash" "$dst_hash" >&2
  exit 1
}
