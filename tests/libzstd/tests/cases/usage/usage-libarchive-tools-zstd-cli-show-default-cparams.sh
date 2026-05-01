#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-show-default-cparams
# @title: zstd CLI --show-default-cparams emits expected parameter rows
# @description: Compresses a known-size payload with --show-default-cparams and asserts the diagnostic banner contains the windowLog/chainLog/hashLog/searchLog/strategy fields and that the underlying compression still produces a valid zstd frame that round-trips byte-for-byte.
# @timeout: 120
# @tags: usage, archive, zstd, cli, params
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"show-default-cparams payload row\n" * 1024)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

# --show-default-cparams writes the parameter banner to stderr and still
# produces a real .zst output.
zstd --show-default-cparams -o "$tmpdir/out.zst" "$src" \
  >"$tmpdir/stdout.log" 2>"$tmpdir/stderr.log"

validator_require_file "$tmpdir/out.zst"
magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# All five parameter rows must be present in the banner.
combined="$tmpdir/combined.log"
cat "$tmpdir/stdout.log" "$tmpdir/stderr.log" >"$combined"
grep -q 'windowLog' "$combined"
grep -q 'chainLog' "$combined"
grep -q 'hashLog' "$combined"
grep -q 'searchLog' "$combined"
grep -q 'strategy' "$combined"

zstd -tq "$tmpdir/out.zst"
zstd -dq -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
