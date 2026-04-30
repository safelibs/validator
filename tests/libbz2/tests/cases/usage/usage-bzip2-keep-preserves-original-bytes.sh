#!/usr/bin/env bash
# @testcase: usage-bzip2-keep-preserves-original-bytes
# @title: bzip2 -k preserves original bytes alongside .bz2
# @description: Compresses a file with bzip2 -k and verifies the original is preserved byte-for-byte while a non-empty valid .bz2 is produced.
# @timeout: 180
# @tags: usage, bzip2
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-keep-preserves-original-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a deterministic mixed-content input (text + binary-ish bytes).
python3 -c 'import sys
sys.stdout.buffer.write(b"keep flag preservation header\n")
sys.stdout.buffer.write(bytes(range(256)) * 8)
sys.stdout.buffer.write(b"\nkeep flag preservation footer\n")' >"$tmpdir/data.bin"

# Snapshot the original digest BEFORE compression.
expected_sha=$(sha256sum "$tmpdir/data.bin" | awk '{print $1}')
expected_size=$(wc -c <"$tmpdir/data.bin")

# Stash a pristine copy to compare against later.
cp "$tmpdir/data.bin" "$tmpdir/data.orig"

bzip2 -k "$tmpdir/data.bin"

# Original must still exist with identical bytes.
validator_require_file "$tmpdir/data.bin"
actual_sha=$(sha256sum "$tmpdir/data.bin" | awk '{print $1}')
actual_size=$(wc -c <"$tmpdir/data.bin")
[[ "$actual_sha" == "$expected_sha" ]] || {
  printf 'original sha changed: expected %s got %s\n' "$expected_sha" "$actual_sha" >&2
  exit 1
}
[[ "$actual_size" -eq "$expected_size" ]] || {
  printf 'original size changed: expected %s got %s\n' "$expected_size" "$actual_size" >&2
  exit 1
}
cmp "$tmpdir/data.bin" "$tmpdir/data.orig"

# .bz2 must exist, be non-empty, validate, and round-trip to the original.
validator_require_file "$tmpdir/data.bin.bz2"
bz_size=$(wc -c <"$tmpdir/data.bin.bz2")
[[ "$bz_size" -gt 0 ]] || {
  printf '.bz2 is empty\n' >&2
  exit 1
}
bzip2 -t "$tmpdir/data.bin.bz2"
bzip2 -dc "$tmpdir/data.bin.bz2" >"$tmpdir/round.bin"
cmp "$tmpdir/data.orig" "$tmpdir/round.bin"
