#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r16-cli-concatenated-frames-decode
# @title: zstd -d decodes two concatenated frames produced separately into the concatenated source payload
# @description: Compresses two distinct payloads into separate .zst frames, concatenates the two .zst files into one, and asserts zstd -d on the concatenation decodes to the byte-for-byte concatenation of the two original sources, exercising the multi-frame concatenated decode path.
# @timeout: 60
# @tags: usage, archive, zstd, cli, multi-frame
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import sys
sys.stdout.buffer.write(b"r16 multiframe alpha row\n" * 200)' >"$tmpdir/a.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r16 multiframe bravo row\n" * 300)' >"$tmpdir/b.bin"

cat "$tmpdir/a.bin" "$tmpdir/b.bin" >"$tmpdir/combined.bin"
combined_sum=$(sha256sum "$tmpdir/combined.bin" | awk '{print $1}')

zstd -q -o "$tmpdir/a.zst" "$tmpdir/a.bin"
zstd -q -o "$tmpdir/b.zst" "$tmpdir/b.bin"
cat "$tmpdir/a.zst" "$tmpdir/b.zst" >"$tmpdir/multi.zst"

zstd -dq -c "$tmpdir/multi.zst" >"$tmpdir/decoded.bin"
test "$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')" = "$combined_sum"
