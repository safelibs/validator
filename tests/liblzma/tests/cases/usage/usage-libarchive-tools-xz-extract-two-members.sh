#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-extract-two-members
# @title: libarchive-tools xz extract two members
# @description: Extracts two selected members from an xz-compressed tar and verifies only the requested files are restored.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-extract-two-members"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/root/dir/sub" "$tmpdir/out"
printf 'alpha\n' >"$tmpdir/in/root/alpha.txt"
printf 'beta\n' >"$tmpdir/in/root/dir/beta.txt"
printf 'gamma\n' >"$tmpdir/in/root/dir/sub/gamma.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" root
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out" root/alpha.txt root/dir/beta.txt
validator_assert_contains "$tmpdir/out/root/alpha.txt" 'alpha'
validator_assert_contains "$tmpdir/out/root/dir/beta.txt" 'beta'
test ! -e "$tmpdir/out/root/dir/sub/gamma.txt"
