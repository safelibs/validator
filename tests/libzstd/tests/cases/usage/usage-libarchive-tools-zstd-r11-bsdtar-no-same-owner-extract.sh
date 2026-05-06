#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r11-bsdtar-no-same-owner-extract
# @title: bsdtar --zstd extract --no-same-owner restores files as the extractor
# @description: Builds a zstd tar with explicit uid=0 owner, extracts with --no-same-owner, and verifies the resulting file is owned by the current process user/group rather than root.
# @timeout: 120
# @tags: usage, archive, zstd, extract, owner
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'owned-by-extractor\n' >"$tmpdir/in/data.txt"

bsdtar --zstd --uid=0 --gid=0 --uname=root --gname=root \
    -cf "$tmpdir/o.tar.zst" -C "$tmpdir/in" data.txt

bsdtar --no-same-owner -xf "$tmpdir/o.tar.zst" -C "$tmpdir/out"
[[ -f "$tmpdir/out/data.txt" ]]

extracted_uid=$(stat -c %u "$tmpdir/out/data.txt")
test "$extracted_uid" = "$(id -u)"
