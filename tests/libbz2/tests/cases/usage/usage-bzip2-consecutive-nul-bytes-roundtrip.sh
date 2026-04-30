#!/usr/bin/env bash
# @testcase: usage-bzip2-consecutive-nul-bytes-roundtrip
# @title: bzip2 round-trips a file with long runs of consecutive NUL bytes
# @description: Builds a payload dominated by long runs of consecutive NUL (0x00) bytes interleaved with short ASCII markers, compresses with bzip2, decompresses it back, and verifies every NUL is preserved at the same offset and count.
# @timeout: 180
# @tags: usage, bzip2, binary, nulls
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 4096 NULs, marker, 8192 NULs, marker, 1024 NULs.
python3 -c '
import sys
out = (b"\x00" * 4096) + b"MARKER-A\n" + (b"\x00" * 8192) + b"MARKER-B\n" + (b"\x00" * 1024)
sys.stdout.buffer.write(out)
' >"$tmpdir/in.bin"

expected_nuls=$((4096 + 8192 + 1024))
# 9 bytes per "MARKER-X\n" segment.
expected_size=$((4096 + 9 + 8192 + 9 + 1024))

input_size=$(wc -c <"$tmpdir/in.bin")
[[ "$input_size" -eq "$expected_size" ]] || {
  printf 'unexpected input size: got %s, want %s\n' "$input_size" "$expected_size" >&2
  exit 1
}

original_sha=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')

bzip2 -k "$tmpdir/in.bin"
validator_require_file "$tmpdir/in.bin.bz2"
bzip2 -dc "$tmpdir/in.bin.bz2" >"$tmpdir/out.bin"

cmp "$tmpdir/in.bin" "$tmpdir/out.bin"
[[ "$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')" == "$original_sha" ]]

# Confirm the NUL count and offsets are identical.
python3 -c '
import sys
a = open(sys.argv[1], "rb").read()
b = open(sys.argv[2], "rb").read()
ai = [i for i, c in enumerate(a) if c == 0]
bi = [i for i, c in enumerate(b) if c == 0]
assert len(ai) == '"$expected_nuls"', (len(ai), '"$expected_nuls"')
assert ai == bi, "NUL offsets diverged"
print(f"preserved {len(ai)} NULs across {len(set(ai))} positions", file=sys.stderr)
' "$tmpdir/in.bin" "$tmpdir/out.bin"
