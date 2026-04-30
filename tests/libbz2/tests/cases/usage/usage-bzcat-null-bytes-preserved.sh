#!/usr/bin/env bash
# @testcase: usage-bzcat-null-bytes-preserved
# @title: bzcat preserves embedded null bytes
# @description: Compresses a binary payload that contains embedded NUL (0x00) bytes interleaved with ASCII text and verifies bzcat decompression reproduces the bytes exactly, with NULs intact and at the original offsets.
# @timeout: 180
# @tags: usage, bzip2, binary, nulls
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a payload with explicit NUL bytes interleaved between ASCII chunks.
python3 -c 'import sys
chunks = [b"alpha", b"\x00\x00", b"beta", b"\x00", b"gamma", b"\x00\x00\x00", b"delta"]
sys.stdout.buffer.write(b"".join(chunks))' >"$tmpdir/in.bin"

input_size=$(wc -c <"$tmpdir/in.bin")
expected_size=$(( 5 + 2 + 4 + 1 + 5 + 3 + 5 ))
[[ "$input_size" -eq "$expected_size" ]] || {
  printf 'unexpected input size: got %s, want %s\n' "$input_size" "$expected_size" >&2
  exit 1
}
expected_sha=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')

# Confirm the input really does contain NUL bytes (sanity check).
nul_count_in=$(python3 -c 'import sys
data = open(sys.argv[1], "rb").read()
print(data.count(b"\x00"))' "$tmpdir/in.bin")
[[ "$nul_count_in" -eq 6 ]] || {
  printf 'expected 6 NULs in input, got %s\n' "$nul_count_in" >&2
  exit 1
}

bzip2 -k "$tmpdir/in.bin"
validator_require_file "$tmpdir/in.bin.bz2"

bzcat "$tmpdir/in.bin.bz2" >"$tmpdir/out.bin"
cmp "$tmpdir/in.bin" "$tmpdir/out.bin"
[[ "$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')" == "$expected_sha" ]]

# NUL bytes must survive the round-trip at the same count and offsets.
nul_count_out=$(python3 -c 'import sys
data = open(sys.argv[1], "rb").read()
print(data.count(b"\x00"))' "$tmpdir/out.bin")
[[ "$nul_count_out" -eq 6 ]] || {
  printf 'expected 6 NULs in output, got %s\n' "$nul_count_out" >&2
  exit 1
}

python3 -c 'import sys
a = open(sys.argv[1], "rb").read()
b = open(sys.argv[2], "rb").read()
ai = [i for i, c in enumerate(a) if c == 0]
bi = [i for i, c in enumerate(b) if c == 0]
assert ai == bi, f"NUL offsets differ: {ai} vs {bi}"
print("nul offsets:", ai)' "$tmpdir/in.bin" "$tmpdir/out.bin" >&2
