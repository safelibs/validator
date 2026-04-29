#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-rootdir-hidden-file
# @title: libarchive-tools zstd root hidden file
# @description: Archives and extracts a hidden file under a root directory in a zstd-compressed tar and verifies the restored payload.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-rootdir-hidden-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/root" "$tmpdir/out"
printf 'hidden payload\n' >"$tmpdir/in/root/.hidden"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" root
bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/root/.hidden" 'hidden payload'
