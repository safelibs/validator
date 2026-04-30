#!/usr/bin/env bash
# @testcase: usage-bzip2-explicit-levels-block-byte
# @title: bzip2 -2 -5 -8 set the block-size header byte
# @description: Compresses the same payload at three explicit non-extreme levels and verifies the fourth header byte encodes the requested level.
# @timeout: 240
# @tags: usage, bzip2, levels, format
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-explicit-levels-block-byte"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# A reasonably sized, compressible payload exercises the block-size knob.
python3 -c 'import sys
for i in range(1024):
    sys.stdout.write(f"explicit level payload row {i}\n")' >"$tmpdir/in.txt"

read_block_byte_hex() {
  od -An -N1 -tx1 -j3 "$1" | tr -d ' \n'
}

for level in 2 5 8; do
  bzip2 "-${level}" -c "$tmpdir/in.txt" >"$tmpdir/L${level}.bz2"
  # Stream must validate.
  bzip2 -t "$tmpdir/L${level}.bz2"
  # First three bytes must be the BZh magic.
  magic=$(head -c 3 "$tmpdir/L${level}.bz2")
  [[ "$magic" == "BZh" ]] || {
    printf 'level %s magic mismatch: %q\n' "$level" "$magic" >&2
    exit 1
  }
  # Block-size byte: '0'+level == 0x32/0x35/0x38.
  expected_hex=$(printf '%x' $((0x30 + level)))
  actual_hex=$(read_block_byte_hex "$tmpdir/L${level}.bz2")
  [[ "$actual_hex" == "$expected_hex" ]] || {
    printf 'level %s expected block byte 0x%s, got 0x%s\n' "$level" "$expected_hex" "$actual_hex" >&2
    exit 1
  }
  # Round-trip must reproduce the original bytes.
  bzip2 -dc "$tmpdir/L${level}.bz2" >"$tmpdir/L${level}.out"
  cmp "$tmpdir/in.txt" "$tmpdir/L${level}.out"
done
