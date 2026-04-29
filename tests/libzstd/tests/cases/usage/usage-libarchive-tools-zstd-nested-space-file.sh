#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-nested-space-file
# @title: libarchive-tools zstd nested spaced file
# @description: Archives and extracts a nested filename containing spaces in a zstd-compressed tar and verifies the restored payload.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-nested-space-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/root/dir space" "$tmpdir/out"
printf 'space payload\n' >"$tmpdir/in/root/dir space/delta.txt"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" 'root/dir space/delta.txt'
bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/root/dir space/delta.txt" 'space payload'
