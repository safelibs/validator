#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r10-bsdtar-extract-stdout
# @title: bsdtar -xOf single member from xz archive
# @description: Builds a multi-member tar.xz with bsdtar, then extracts a single named member through the liblzma decoder via bsdtar -xOf and asserts the captured stdout matches that member byte-for-byte.
# @timeout: 180
# @tags: usage, archive, xz, bsdtar
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'alpha-member-bytes\n' >"$tmpdir/in/alpha.txt"
printf 'beta-member-bytes-larger\n' >"$tmpdir/in/beta.txt"
printf 'gamma-member-bytes-larger-still\n' >"$tmpdir/in/gamma.txt"

bsdtar -cJf "$tmpdir/multi.tar.xz" -C "$tmpdir/in" alpha.txt beta.txt gamma.txt

bsdtar -xOf "$tmpdir/multi.tar.xz" beta.txt >"$tmpdir/captured.txt"
cmp "$tmpdir/in/beta.txt" "$tmpdir/captured.txt"

# Other members should not appear in the captured stream.
! grep -q 'alpha-member-bytes' "$tmpdir/captured.txt"
! grep -q 'gamma-member-bytes' "$tmpdir/captured.txt"
