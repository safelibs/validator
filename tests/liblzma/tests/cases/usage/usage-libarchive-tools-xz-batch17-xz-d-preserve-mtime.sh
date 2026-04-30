#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch17-xz-d-preserve-mtime
# @title: xz -d preserves source mtime
# @description: Compresses a fixture with xz, captures the source mtime, decompresses with xz -d, and confirms the decompressed file's mtime matches the original (xz preserves timestamps by default).
# @timeout: 180
# @tags: usage, archive, xz, cli, mtime
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/work"
printf 'preserve me\nrow two\nrow three\n' >"$tmpdir/work/data.txt"
# Pin a deterministic mtime so we can compare exactly.
touch -d '2019-03-14T15:09:26Z' "$tmpdir/work/data.txt"
mtime_orig=$(stat -c %Y "$tmpdir/work/data.txt")
sha_orig=$(sha256sum "$tmpdir/work/data.txt" | awk '{print $1}')

# Compress in place: xz consumes data.txt and produces data.txt.xz with the
# same mtime as the source.
xz "$tmpdir/work/data.txt"
test ! -e "$tmpdir/work/data.txt"
test -f "$tmpdir/work/data.txt.xz"

mtime_xz=$(stat -c %Y "$tmpdir/work/data.txt.xz")
test "$mtime_orig" = "$mtime_xz"

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/work/data.txt.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Decompress in place; the resulting data.txt must regain the original mtime.
xz -d "$tmpdir/work/data.txt.xz"
test ! -e "$tmpdir/work/data.txt.xz"
test -f "$tmpdir/work/data.txt"

mtime_dec=$(stat -c %Y "$tmpdir/work/data.txt")
test "$mtime_orig" = "$mtime_dec"

sha_dec=$(sha256sum "$tmpdir/work/data.txt" | awk '{print $1}')
test "$sha_orig" = "$sha_dec"
