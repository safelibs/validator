#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r13-check-none-then-sha256
# @title: xz --check=none and --check=sha256 both roundtrip the same payload
# @description: Compresses one payload twice, once with --check=none and once with --check=sha256, asserts both archives have the .xz magic bytes, both pass "xz -t" integrity, and both decode byte-equal to the source.
# @timeout: 90
# @tags: usage, xz, check, integrity
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'check-variant payload contents\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz --check=none -c "$tmpdir/in.txt" >"$tmpdir/none.xz"
xz --check=sha256 -c "$tmpdir/in.txt" >"$tmpdir/sha256.xz"

for f in none.xz sha256.xz; do
    magic_hex=$(head -c 6 "$tmpdir/$f" | od -An -tx1 | tr -d ' \n')
    test "$magic_hex" = "fd377a585a00"
    xz -t "$tmpdir/$f"
done

xz -d -c "$tmpdir/none.xz" >"$tmpdir/d_none.txt"
xz -d -c "$tmpdir/sha256.xz" >"$tmpdir/d_sha.txt"
test "$src_sha" = "$(sha256sum "$tmpdir/d_none.txt" | awk '{print $1}')"
test "$src_sha" = "$(sha256sum "$tmpdir/d_sha.txt" | awk '{print $1}')"
