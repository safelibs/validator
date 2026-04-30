#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-tiny-payload-magic
# @title: bsdtar zstd tiny payload preserves magic
# @description: Archives a single 7-byte payload with bsdtar --zstd and verifies the resulting frame still carries the 28 b5 2f fd zstd magic and round-trips byte-exact, exercising the small-input path.
# @timeout: 120
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"

# Exactly 7 bytes -- well under 32, so the encoder path for "tiny" inputs
# must still emit a valid zstd frame with the standard magic prefix.
printf 'tiny!!\n' >"$tmpdir/in/t.bin"
test "$(stat -c %s "$tmpdir/in/t.bin")" = "7"

src_sum=$(sha256sum "$tmpdir/in/t.bin" | awk '{print $1}')

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" t.bin
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

dst_sum=$(sha256sum "$tmpdir/out/t.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
