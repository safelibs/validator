#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch18-bsdcpio-tv-verbose-xz
# @title: bsdcpio -tv verbose listing of xz cpio
# @description: Builds a newc cpio compressed with xz, then runs bsdcpio -i -tv on the decompressed stream and asserts verbose mode prints permission columns alongside both member names.
# @timeout: 180
# @tags: usage, archive, xz, cpio, verbose
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/work"
printf 'verbose alpha body\n' >"$tmpdir/src/alpha.txt"
printf 'verbose epsilon body\n' >"$tmpdir/src/epsilon.txt"
chmod 0644 "$tmpdir/src/alpha.txt" "$tmpdir/src/epsilon.txt"

cd "$tmpdir/src"
printf 'alpha.txt\nepsilon.txt\n' | bsdcpio -o -H newc 2>/dev/null | xz -z -c >"$tmpdir/work/a.cpio.xz"

magic_hex=$(head -c 6 "$tmpdir/work/a.cpio.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

xz -d -c "$tmpdir/work/a.cpio.xz" | bsdcpio -i -tv >"$tmpdir/work/list" 2>/dev/null
validator_assert_contains "$tmpdir/work/list" 'alpha.txt'
validator_assert_contains "$tmpdir/work/list" 'epsilon.txt'
# Verbose listing should expose POSIX mode strings starting with '-' for regular files.
grep -E '^-rw-' "$tmpdir/work/list" >/dev/null
