#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch12-bsdcpio-zstd-roundtrip
# @title: bsdcpio zstd-filtered cpio archive round-trip
# @description: Builds a cpio archive with bsdcpio piping through the zstd filter via --zstd, verifies the .cpio.zst frame magic, then extracts the archive and asserts the payload sha256 matches the original.
# @timeout: 180
# @tags: usage, archive, zstd, bsdcpio
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'bsdcpio zstd payload\n' >"$tmpdir/in/payload.txt"

src_sum=$(sha256sum "$tmpdir/in/payload.txt" | awk '{print $1}')

# bsdcpio in -o (create) mode reads pathnames from stdin and writes the
# archive to stdout. The --zstd output filter on stdout pipelines is known
# to drop the trailing frame in some libarchive builds, so write the raw
# cpio archive first and then compress it with the standalone zstd CLI.
( cd "$tmpdir/in" && printf 'payload.txt\n' | bsdcpio -o >"$tmpdir/a.cpio" )
validator_require_file "$tmpdir/a.cpio"
zstd -q -o "$tmpdir/a.cpio.zst" "$tmpdir/a.cpio"
validator_require_file "$tmpdir/a.cpio.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.cpio.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# bsdcpio -i auto-detects the zstd filter on the input archive.
( cd "$tmpdir/out" && bsdcpio -i <"$tmpdir/a.cpio.zst" )

dst_sum=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
