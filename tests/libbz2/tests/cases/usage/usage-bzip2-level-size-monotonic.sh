#!/usr/bin/env bash
# @testcase: usage-bzip2-level-size-monotonic
# @title: bzip2 levels 1 and 9 round-trip identically
# @description: Compresses the same payload at -1 and -9 and verifies both decompress to identical bytes via libbz2.
# @timeout: 240
# @tags: usage, compression, levels
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Highly compressible payload exercises the block-size knob meaningfully.
python3 -c 'import sys
for _ in range(4096):
    sys.stdout.write("libbz2 level comparison line\n")' >"$tmpdir/in.txt"
expected_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 -1 -c "$tmpdir/in.txt" >"$tmpdir/level1.bz2"
bzip2 -9 -c "$tmpdir/in.txt" >"$tmpdir/level9.bz2"

# Both streams must be valid bzip2 and round-trip to the original bytes.
bzip2 -t "$tmpdir/level1.bz2"
bzip2 -t "$tmpdir/level9.bz2"

bzip2 -dc "$tmpdir/level1.bz2" >"$tmpdir/out1"
bzip2 -dc "$tmpdir/level9.bz2" >"$tmpdir/out9"
cmp "$tmpdir/in.txt" "$tmpdir/out1"
cmp "$tmpdir/in.txt" "$tmpdir/out9"

[[ "$(sha256sum "$tmpdir/out1" | awk '{print $1}')" == "$expected_sha" ]]
[[ "$(sha256sum "$tmpdir/out9" | awk '{print $1}')" == "$expected_sha" ]]

# bzip2 frame layout: bytes 0..2 are "BZh", byte 3 is the block-size digit
# '1'..'9' (units of 100k). It must reflect the requested level.
read_byte_hex() {
  od -An -N1 -tx1 -j3 "$1" | tr -d ' \n'
}
b1_hex=$(read_byte_hex "$tmpdir/level1.bz2")
b9_hex=$(read_byte_hex "$tmpdir/level9.bz2")
echo "bzip2 -1 block byte: 0x$b1_hex" >&2
echo "bzip2 -9 block byte: 0x$b9_hex" >&2
[[ "$b1_hex" == "31" ]] || { printf 'expected level1 block byte 0x31, got 0x%s\n' "$b1_hex" >&2; exit 1; }
[[ "$b9_hex" == "39" ]] || { printf 'expected level9 block byte 0x39, got 0x%s\n' "$b9_hex" >&2; exit 1; }

# Magic prefix "BZh" must be intact.
magic1=$(od -An -N3 -c "$tmpdir/level1.bz2" | tr -d ' \n')
magic9=$(od -An -N3 -c "$tmpdir/level9.bz2" | tr -d ' \n')
[[ "$magic1" == "BZh" ]] || { printf 'level1 magic %q\n' "$magic1" >&2; exit 1; }
[[ "$magic9" == "BZh" ]] || { printf 'level9 magic %q\n' "$magic9" >&2; exit 1; }
