#!/usr/bin/env bash
# @testcase: usage-bzip2-highly-compressible-size-strictly-decreasing
# @title: bzip2 -1 strictly larger than -9 on repeating text
# @description: Compresses a deeply repetitive text payload at -1 and -9 and verifies the -9 output is strictly smaller than -1, with both rounds-tripping to identical original bytes via libbz2.
# @timeout: 240
# @tags: usage, bzip2, levels, compressible
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Single repeating ASCII line, repeated enough times to exceed the level-1
# block size (100 KiB) several times over. With redundancy this high, a
# larger block size (-9 = 900 KiB) is guaranteed to compress more tightly
# than the smallest block size (-1 = 100 KiB).
python3 -c 'import sys
line = "highly-compressible repeating payload row\n"
for _ in range(40000):
    sys.stdout.write(line)' >"$tmpdir/in.txt"

input_size=$(wc -c <"$tmpdir/in.txt")
[[ "$input_size" -gt 1000000 ]] || {
  printf 'expected input >1000000 bytes, got %s\n' "$input_size" >&2
  exit 1
}
expected_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 -1 -c "$tmpdir/in.txt" >"$tmpdir/level1.bz2"
bzip2 -9 -c "$tmpdir/in.txt" >"$tmpdir/level9.bz2"

bzip2 -t "$tmpdir/level1.bz2"
bzip2 -t "$tmpdir/level9.bz2"

size1=$(wc -c <"$tmpdir/level1.bz2")
size9=$(wc -c <"$tmpdir/level9.bz2")
echo "compressible -1 size: $size1" >&2
echo "compressible -9 size: $size9" >&2

# Both outputs must be dramatically smaller than the input.
[[ "$size1" -lt "$input_size" ]]
[[ "$size9" -lt "$input_size" ]]

# -9 must be strictly smaller than -1 on this highly redundant payload.
[[ "$size9" -lt "$size1" ]] || {
  printf 'expected size9 < size1, got %s !< %s\n' "$size9" "$size1" >&2
  exit 1
}

# Round-trip both back to bytes and confirm sha256 matches.
bzip2 -dc "$tmpdir/level1.bz2" >"$tmpdir/out1"
bzip2 -dc "$tmpdir/level9.bz2" >"$tmpdir/out9"
cmp "$tmpdir/in.txt" "$tmpdir/out1"
cmp "$tmpdir/in.txt" "$tmpdir/out9"
[[ "$(sha256sum "$tmpdir/out1" | awk '{print $1}')" == "$expected_sha" ]]
[[ "$(sha256sum "$tmpdir/out9" | awk '{print $1}')" == "$expected_sha" ]]
