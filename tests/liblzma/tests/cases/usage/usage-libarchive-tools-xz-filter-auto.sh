#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-filter-auto
# @title: libarchive-tools xz filter auto
# @description: Runs bsdtar filter auto on a xz-compressed archive through liblzma.
# @timeout: 180
# @tags: usage, archive, compression
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'filter-auto\n' >"$tmpdir/in/payload.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" .
bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/payload.txt" 'filter-auto'
