#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r16-zstdcat-multiple-inputs-concat
# @title: zstdcat with two .zst arguments emits the concatenated decoded payload on stdout
# @description: Compresses two distinct payloads into separate .zst files, runs zstdcat with both files as arguments, and asserts the captured stdout SHA-256 equals the SHA-256 of the concatenation of the two original sources — exercising the multi-input zstdcat path.
# @timeout: 60
# @tags: usage, archive, zstd, cli, zstdcat
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import sys
sys.stdout.buffer.write(b"r16 zstdcat alpha row\n" * 250)' >"$tmpdir/a.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r16 zstdcat bravo row\n" * 350)' >"$tmpdir/b.bin"

cat "$tmpdir/a.bin" "$tmpdir/b.bin" >"$tmpdir/combined.bin"
combined_sum=$(sha256sum "$tmpdir/combined.bin" | awk '{print $1}')

zstd -q -o "$tmpdir/a.zst" "$tmpdir/a.bin"
zstd -q -o "$tmpdir/b.zst" "$tmpdir/b.bin"

zstdcat "$tmpdir/a.zst" "$tmpdir/b.zst" >"$tmpdir/out.bin"
test "$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')" = "$combined_sum"
