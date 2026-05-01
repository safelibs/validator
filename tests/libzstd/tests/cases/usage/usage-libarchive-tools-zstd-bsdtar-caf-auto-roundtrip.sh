#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdtar-caf-auto-roundtrip
# @title: bsdtar -caf auto-selects zstd from .tar.zst suffix
# @description: Builds a tree, asks bsdtar to create an archive with -caf and a .tar.zst suffix so the auto-compress path picks the libarchive zstd writer, asserts the zstd frame magic, lists members, and round-trips to a sha256-identical extract.
# @timeout: 180
# @tags: usage, archive, zstd, bsdtar, caf
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub" "$tmpdir/out"
python3 -c 'import sys
sys.stdout.buffer.write(b"caf-auto payload alpha\n" * 1024)' >"$tmpdir/in/alpha.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"caf-auto payload beta\n" * 1024)' >"$tmpdir/in/sub/beta.bin"

src_alpha=$(sha256sum "$tmpdir/in/alpha.bin" | awk '{print $1}')
src_beta=$(sha256sum "$tmpdir/in/sub/beta.bin" | awk '{print $1}')

bsdtar -caf "$tmpdir/auto.tar.zst" -C "$tmpdir/in" alpha.bin sub/beta.bin
validator_require_file "$tmpdir/auto.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/auto.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -tf "$tmpdir/auto.tar.zst" >"$tmpdir/list.txt"
grep -qx 'alpha.bin' "$tmpdir/list.txt"
grep -qx 'sub/beta.bin' "$tmpdir/list.txt"

bsdtar -xf "$tmpdir/auto.tar.zst" -C "$tmpdir/out"
dst_alpha=$(sha256sum "$tmpdir/out/alpha.bin" | awk '{print $1}')
dst_beta=$(sha256sum "$tmpdir/out/sub/beta.bin" | awk '{print $1}')
test "$src_alpha" = "$dst_alpha"
test "$src_beta" = "$dst_beta"
