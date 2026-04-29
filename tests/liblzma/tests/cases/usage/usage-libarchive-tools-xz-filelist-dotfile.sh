#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-filelist-dotfile
# @title: libarchive-tools xz filelist dotfile
# @description: Builds an xz-compressed tar from a file list containing a dotfile and verifies both listed members are present.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-filelist-dotfile"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/root"
printf 'alpha\n' >"$tmpdir/in/root/alpha.txt"
printf 'hidden\n' >"$tmpdir/in/root/.hidden"
printf 'root/.hidden\nroot/alpha.txt\n' >"$tmpdir/files.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" -T "$tmpdir/files.txt"
bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'root/.hidden'
validator_assert_contains "$tmpdir/list" 'root/alpha.txt'
