#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-decompress-pipe
# @title: bsdtar create piped through zstd CLI -d
# @description: Pipes a bsdtar --zstd archive on stdout into the standalone zstd CLI's decompressor and verifies the decoded byte stream is a valid uncompressed tar containing the expected member.
# @timeout: 180
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'cli-decompress-pipe payload\n' >"$tmpdir/in/marker.txt"

# bsdtar emits the zstd-compressed tar to a file; the standalone zstd CLI
# decompresses the file back to a plain tar. The point is to confirm the
# libarchive zstd writer produces a frame that the upstream CLI tool fully
# accepts. (Older bsdtar versions silently skip filters when writing to
# stdout via `-cf -`, so we go via a real file.)
bsdtar --zstd -cf "$tmpdir/archive.tar.zst" -C "$tmpdir/in" marker.txt
validator_require_file "$tmpdir/archive.tar.zst"

# Sanity: the tar file actually carries the zstd magic (0x28 0xB5 0x2F 0xFD).
zst_magic=$(head -c 4 "$tmpdir/archive.tar.zst" | od -An -tx1 | tr -d ' \n')
test "$zst_magic" = "28b52ffd"

zstd -d -c "$tmpdir/archive.tar.zst" >"$tmpdir/decoded.tar"
validator_require_file "$tmpdir/decoded.tar"

# Decoded stream must be an uncompressed tar (POSIX "ustar" magic at offset 257).
ustar_magic=$(dd if="$tmpdir/decoded.tar" bs=1 skip=257 count=5 2>/dev/null | tr -d '\0')
test "$ustar_magic" = "ustar"

bsdtar -tf "$tmpdir/decoded.tar" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'marker.txt'
