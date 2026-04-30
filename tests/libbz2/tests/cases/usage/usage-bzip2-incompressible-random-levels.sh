#!/usr/bin/env bash
# @testcase: usage-bzip2-incompressible-random-levels
# @title: bzip2 -1 and -9 produce near-equal sizes on random data
# @description: Compresses an incompressible random binary payload at -1 and -9 and verifies both streams round-trip and end up within a small relative size of each other (incompressible input cannot be meaningfully shrunk by any block size).
# @timeout: 240
# @tags: usage, bzip2, levels, incompressible
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 256 KiB of cryptographically-random bytes. Random data is, by definition,
# incompressible, so the block-size knob (-1 vs -9) cannot meaningfully
# shrink the output beyond constant per-block framing overhead.
python3 -c 'import os, sys
sys.stdout.buffer.write(os.urandom(262144))' >"$tmpdir/in.bin"

input_size=$(wc -c <"$tmpdir/in.bin")
[[ "$input_size" -eq 262144 ]] || {
  printf 'expected 262144 bytes, got %s\n' "$input_size" >&2
  exit 1
}

bzip2 -1 -c "$tmpdir/in.bin" >"$tmpdir/level1.bz2"
bzip2 -9 -c "$tmpdir/in.bin" >"$tmpdir/level9.bz2"

bzip2 -t "$tmpdir/level1.bz2"
bzip2 -t "$tmpdir/level9.bz2"

size1=$(wc -c <"$tmpdir/level1.bz2")
size9=$(wc -c <"$tmpdir/level9.bz2")
echo "incompressible -1 size: $size1" >&2
echo "incompressible -9 size: $size9" >&2

# Both compressed outputs should be larger than the random input
# (random data does not compress; framing overhead dominates).
[[ "$size1" -ge "$input_size" ]] || {
  printf 'expected -1 size >= input, got %s vs %s\n' "$size1" "$input_size" >&2
  exit 1
}
[[ "$size9" -ge "$input_size" ]] || {
  printf 'expected -9 size >= input, got %s vs %s\n' "$size9" "$input_size" >&2
  exit 1
}

# The two sizes should be within 5% of each other: block-size choice cannot
# rescue incompressible data.
abs_diff=$(( size1 > size9 ? size1 - size9 : size9 - size1 ))
max_size=$(( size1 > size9 ? size1 : size9 ))
# 5% threshold expressed as 20 * abs_diff <= max_size.
[[ $((20 * abs_diff)) -le "$max_size" ]] || {
  printf 'sizes differ by more than 5%%: -1=%s -9=%s diff=%s\n' \
    "$size1" "$size9" "$abs_diff" >&2
  exit 1
}

# Both streams must round-trip to the original random bytes.
bzip2 -dc "$tmpdir/level1.bz2" >"$tmpdir/out1.bin"
bzip2 -dc "$tmpdir/level9.bz2" >"$tmpdir/out9.bin"
cmp "$tmpdir/in.bin" "$tmpdir/out1.bin"
cmp "$tmpdir/in.bin" "$tmpdir/out9.bin"
