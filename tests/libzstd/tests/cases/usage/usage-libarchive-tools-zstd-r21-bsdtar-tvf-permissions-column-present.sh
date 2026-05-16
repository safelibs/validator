#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r21-bsdtar-tvf-permissions-column-present
# @title: bsdtar --zstd -tvf lists each member with a permission-bit column matching the source mode
# @description: Creates a tar.zst archive containing a regular file with mode 0644, lists it with bsdtar --zstd -tvf and asserts the listing's first column for that member matches '-rw-r--r--' — pinning libarchive's zst listing's permission column on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, tvf, permissions, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src=$tmpdir/src
mkdir -p "$src"
printf 'r21 perms\n' >"$src/payload.txt"
chmod 0644 "$src/payload.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir" src

bsdtar --zstd -tvf "$tmpdir/a.tar.zst" >"$tmpdir/list.txt"
# Locate the line for payload.txt.
grep 'payload.txt$' "$tmpdir/list.txt" >"$tmpdir/line.txt" || { echo "no payload.txt line" >&2; cat "$tmpdir/list.txt" >&2; exit 1; }
first_col=$(awk '{print $1}' "$tmpdir/line.txt")
[[ "$first_col" == "-rw-r--r--" ]] || { printf 'expected -rw-r--r--, got %s\n' "$first_col" >&2; cat "$tmpdir/list.txt" >&2; exit 1; }
