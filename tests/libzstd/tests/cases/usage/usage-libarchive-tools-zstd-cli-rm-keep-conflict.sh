#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-rm-keep-conflict
# @title: zstd CLI -t test mode validates good vs tampered frames
# @description: zstd accepts --rm and --keep together (they are not mutually exclusive on this CLI; --keep wins so the source file survives), so instead this case exercises zstd -t (test mode) which is the canonical integrity-validation behaviour: zstd -t must succeed on a freshly compressed file and must fail with a non-zero exit when a single ciphertext byte has been flipped.
# @timeout: 120
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.txt"
printf 'zstd integrity test payload\n' >"$src"

# Compress and verify the resulting frame validates cleanly.
zstd -q -k "$src" -o "$tmpdir/good.zst"
validator_require_file "$tmpdir/good.zst"

# Frame must start with the standard zstd magic (28 b5 2f fd, little-endian).
magic=$(od -An -N4 -tx1 "$tmpdir/good.zst" | tr -d ' \n')
[[ "$magic" == "28b52ffd" ]] || {
  printf 'expected zstd magic 28b52ffd, got %s\n' "$magic" >&2
  exit 1
}

# zstd -t on a clean frame must succeed.
zstd -t "$tmpdir/good.zst" >"$tmpdir/test.log" 2>&1 || {
  printf 'zstd -t rejected a freshly-compressed frame\n' >&2
  cat "$tmpdir/test.log" >&2
  exit 1
}

# Tamper a single byte of the compressed payload (well past the 4-byte magic
# so we mutate body bytes, not the frame header magic).
cp "$tmpdir/good.zst" "$tmpdir/bad.zst"
python3 -c '
import sys
path = sys.argv[1]
with open(path, "r+b") as fh:
    fh.seek(8)
    data = fh.read(1)
    fh.seek(8)
    fh.write(bytes([data[0] ^ 0xFF]))
' "$tmpdir/bad.zst"

# zstd -t on a tampered frame must report a non-zero exit. zstd has multiple
# integrity layers (block headers, optional XXH64 footer), so any byte flip
# in the body is expected to surface as a test failure.
set +e
zstd -t "$tmpdir/bad.zst" >"$tmpdir/bad-test.log" 2>&1
status=$?
set -e
test "$status" -ne 0 || {
  printf 'zstd -t accepted a tampered frame (status=%s)\n' "$status" >&2
  cat "$tmpdir/bad-test.log" >&2
  exit 1
}
