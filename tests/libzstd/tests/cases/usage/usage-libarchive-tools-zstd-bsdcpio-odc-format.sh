#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdcpio-odc-format
# @title: bsdcpio odc format with zstd-compressed wrapper
# @description: Creates a cpio archive in the odc (POSIX.1) format with bsdcpio, compresses it with the standalone zstd CLI (the bsdcpio --zstd output filter is known to silently drop the trailing frame), then extracts the archive and asserts the payload round-trips by sha256.
# @timeout: 180
# @tags: usage, archive, zstd, bsdcpio
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'bsdcpio odc payload\n' >"$tmpdir/in/payload.txt"
src_sum=$(sha256sum "$tmpdir/in/payload.txt" | awk '{print $1}')

# Build an odc-format cpio archive, then compress separately with the
# standalone zstd CLI to avoid the libarchive output-filter truncation
# documented for `bsdcpio --zstd` on stdout pipelines.
( cd "$tmpdir/in" && printf 'payload.txt\n' | bsdcpio -o -H odc >"$tmpdir/a.cpio" )
validator_require_file "$tmpdir/a.cpio"
zstd -q -o "$tmpdir/a.cpio.zst" "$tmpdir/a.cpio"
validator_require_file "$tmpdir/a.cpio.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.cpio.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# bsdcpio reports the format on -tv listings; assert it is odc.
listing=$(bsdcpio -itv <"$tmpdir/a.cpio" 2>&1 || true)
file_kind=$(file -b "$tmpdir/a.cpio")
case "$file_kind" in
  *POSIX*|*'ASCII cpio'*) ;;
  *)
    printf 'expected odc/POSIX cpio header, got: %s\nlisting: %s\n' "$file_kind" "$listing" >&2
    exit 1
    ;;
esac

( cd "$tmpdir/out" && bsdcpio -i <"$tmpdir/a.cpio.zst" )
validator_require_file "$tmpdir/out/payload.txt"
dst_sum=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
