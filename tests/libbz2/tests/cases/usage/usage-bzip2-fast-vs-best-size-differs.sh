#!/usr/bin/env bash
# @testcase: usage-bzip2-fast-vs-best-size-differs
# @title: bzip2 -1 and -9 produce distinct compressed sizes
# @description: Compresses a highly compressible payload at -1 and -9 and verifies the two outputs differ in size while round-tripping to identical bytes.
# @timeout: 240
# @tags: usage, bzip2, levels
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-fast-vs-best-size-differs"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# A payload comfortably larger than 100k * 1 (level-1 block size) so the
# block-size choice actually changes the output layout.
python3 -c 'import sys
for i in range(20000):
    sys.stdout.write(f"fast vs best comparison row {i % 13}\n")' >"$tmpdir/in.txt"

input_size=$(wc -c <"$tmpdir/in.txt")
[[ "$input_size" -gt 200000 ]] || {
  printf 'expected input >200000 bytes, got %s\n' "$input_size" >&2
  exit 1
}

bzip2 -1 -c "$tmpdir/in.txt" >"$tmpdir/level1.bz2"
bzip2 -9 -c "$tmpdir/in.txt" >"$tmpdir/level9.bz2"

size1=$(wc -c <"$tmpdir/level1.bz2")
size9=$(wc -c <"$tmpdir/level9.bz2")
echo "bzip2 -1 size: $size1" >&2
echo "bzip2 -9 size: $size9" >&2

# Both must be valid bzip2 streams.
bzip2 -t "$tmpdir/level1.bz2"
bzip2 -t "$tmpdir/level9.bz2"

# The two streams must be byte-distinct and have distinct file sizes.
if cmp -s "$tmpdir/level1.bz2" "$tmpdir/level9.bz2"; then
  printf 'level1 and level9 streams should differ\n' >&2
  exit 1
fi
[[ "$size1" -ne "$size9" ]] || {
  printf 'expected different sizes for -1 vs -9, both = %s\n' "$size1" >&2
  exit 1
}

# Round-trip must reproduce the original bytes from both streams.
bzip2 -dc "$tmpdir/level1.bz2" >"$tmpdir/out1"
bzip2 -dc "$tmpdir/level9.bz2" >"$tmpdir/out9"
cmp "$tmpdir/in.txt" "$tmpdir/out1"
cmp "$tmpdir/in.txt" "$tmpdir/out9"
