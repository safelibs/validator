#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-large-file
# @title: libarchive-tools xz large file
# @description: Runs bsdtar large file on a xz-compressed archive through liblzma.
# @timeout: 180
# @tags: usage, archive, compression
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'large-file\n' >"$tmpdir/in/payload.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" .
bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/payload.txt" 'large-file'
