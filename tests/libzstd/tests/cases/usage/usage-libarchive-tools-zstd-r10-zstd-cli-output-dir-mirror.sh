#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r10-zstd-cli-output-dir-mirror
# @title: zstd CLI --output-dir-mirror preserves source tree
# @description: Compresses two files in nested source directories with zstd --output-dir-mirror, asserts the mirrored .zst tree appears under the destination, and decompresses one of the mirrored files to confirm the payload sha256 matches the source.
# @timeout: 180
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src/sub1" "$tmpdir/src/sub2/deeper"
printf 'sub1 payload\n' >"$tmpdir/src/sub1/a.txt"
printf 'sub2 deep payload\n' >"$tmpdir/src/sub2/deeper/b.txt"

src_sum_b=$(sha256sum "$tmpdir/src/sub2/deeper/b.txt" | awk '{print $1}')

mkdir -p "$tmpdir/dst"
( cd "$tmpdir" && zstd -q --output-dir-mirror "$tmpdir/dst" \
    "src/sub1/a.txt" "src/sub2/deeper/b.txt" )

validator_require_file "$tmpdir/dst/src/sub1/a.txt.zst"
validator_require_file "$tmpdir/dst/src/sub2/deeper/b.txt.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/dst/src/sub1/a.txt.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -dq -o "$tmpdir/b.out" "$tmpdir/dst/src/sub2/deeper/b.txt.zst"
dst_sum_b=$(sha256sum "$tmpdir/b.out" | awk '{print $1}')
test "$src_sum_b" = "$dst_sum_b"
