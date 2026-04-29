#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-tar-list
# @title: libarchive-tools zstd tar list
# @description: Runs bsdtar tar list on a zstd-compressed archive through libzstd.
# @timeout: 180
# @tags: usage, archive, compression
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'tar-list\n' >"$tmpdir/in/payload.txt"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" .
bsdtar -tf "$tmpdir/a.tar.zstd" | tee "$tmpdir/list"
bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/payload.txt" 'tar-list'
