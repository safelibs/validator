#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-nested-space-file
# @title: libarchive-tools xz nested spaced file
# @description: Archives and extracts a nested filename containing spaces in an xz-compressed tar and verifies the restored payload.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-nested-space-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/root/dir space" "$tmpdir/out"
printf 'space payload\n' >"$tmpdir/in/root/dir space/delta.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" 'root/dir space/delta.txt'
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/root/dir space/delta.txt" 'space payload'
