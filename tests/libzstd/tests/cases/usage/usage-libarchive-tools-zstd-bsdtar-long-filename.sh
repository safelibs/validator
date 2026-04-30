#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdtar-long-filename
# @title: bsdtar --zstd round-trips a long filename
# @description: Creates a file whose basename is well over the legacy 100-byte ustar name field limit (but still under ext4's 255-byte filename limit, so the source file can actually be created on disk), archives it with bsdtar --zstd (which falls back to the pax format for long names), extracts into a clean directory, and asserts the extracted basename and payload sha256 match the source.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"

# Build a 200-byte basename: well past the ustar 100-byte name field limit
# (so bsdtar must use a long-name extension), but still under ext4's
# 255-byte filename limit so the source file is actually creatable.
long_name=$(python3 -c 'import sys; sys.stdout.write("a" * 200 + ".dat")')
printf 'long-filename payload\n' >"$tmpdir/in/$long_name"
src_sum=$(sha256sum "$tmpdir/in/$long_name" | awk '{print $1}')

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" "$long_name"
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

bsdtar -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"
validator_require_file "$tmpdir/out/$long_name"
dst_sum=$(sha256sum "$tmpdir/out/$long_name" | awk '{print $1}')
test "$src_sum" = "$dst_sum"
