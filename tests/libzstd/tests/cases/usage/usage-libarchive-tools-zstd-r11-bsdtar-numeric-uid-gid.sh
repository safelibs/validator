#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r11-bsdtar-numeric-uid-gid
# @title: bsdtar --zstd --uid=0 --gid=0 records numeric zero owner
# @description: Builds a zstd tar with --uid=0 --gid=0 to override the owner numerics, then asserts the verbose listing reports a 0/0 numeric pair regardless of the host user identity.
# @timeout: 120
# @tags: usage, archive, zstd, owner
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'owned\n' >"$tmpdir/in/payload.txt"

bsdtar --zstd --uid=0 --gid=0 --uname=root --gname=root \
    -cf "$tmpdir/o.tar.zst" -C "$tmpdir/in" payload.txt
bsdtar --numeric-owner -tvf "$tmpdir/o.tar.zst" >"$tmpdir/list"

# verbose listing: <perms> <uid> <gid> <size> ... — assert numeric uid==0 and gid==0
awk '$2 == "0" && $3 == "0" { ok=1 } END { exit ok ? 0 : 1 }' "$tmpdir/list"
