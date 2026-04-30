#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch16-ustar-pipe-xz
# @title: bsdtar ustar piped through xz
# @description: Pipes a bsdtar --format=ustar stream through xz, then re-reads it with bsdtar to verify member round-trip.
# @timeout: 180
# @tags: usage, archive, xz, ustar
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src/sub" "$tmpdir/out"
printf 'alpha payload\n' >"$tmpdir/src/alpha.txt"
printf 'nested payload\n' >"$tmpdir/src/sub/beta.txt"

# Build ustar tar -> xz on stdout pipe -> .tar.xz file.
bsdtar -c --format=ustar -f - -C "$tmpdir/src" . | xz -c >"$tmpdir/a.tar.xz"

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'alpha.txt'
validator_assert_contains "$tmpdir/list" 'sub/beta.txt'

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
cmp "$tmpdir/src/alpha.txt" "$tmpdir/out/alpha.txt"
cmp "$tmpdir/src/sub/beta.txt" "$tmpdir/out/sub/beta.txt"
