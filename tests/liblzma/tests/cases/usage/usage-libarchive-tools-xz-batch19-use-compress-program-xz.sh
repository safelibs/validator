#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch19-use-compress-program-xz
# @title: bsdtar --use-compress-program xz round-trip
# @description: Creates a tar archive piped through xz via bsdtar --use-compress-program=xz and confirms bsdtar reads it back natively through liblzma's auto-detection.
# @timeout: 180
# @tags: usage, archive, xz, compress-program
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'compress-program payload alpha\n' >"$tmpdir/in/alpha.txt"
printf 'compress-program payload beta\n' >"$tmpdir/in/beta.txt"
src_a=$(sha256sum "$tmpdir/in/alpha.txt" | awk '{print $1}')
src_b=$(sha256sum "$tmpdir/in/beta.txt" | awk '{print $1}')

bsdtar --use-compress-program=xz -cf "$tmpdir/a.tar.xz" -C "$tmpdir/in" alpha.txt beta.txt

# .xz magic — even though bsdtar shells out to xz(1) for compression, the
# resulting bytes must be a real .xz stream that liblzma can decode on read.
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Read back natively (no --use-compress-program) so liblzma drives the
# decompression path.
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"

out_a=$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')
out_b=$(sha256sum "$tmpdir/out/beta.txt" | awk '{print $1}')
test "$src_a" = "$out_a"
test "$src_b" = "$out_b"

# Listing should report exactly two entries in deterministic order.
bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
test "$(wc -l <"$tmpdir/list.txt")" -eq 2
grep -Fxq 'alpha.txt' "$tmpdir/list.txt"
grep -Fxq 'beta.txt' "$tmpdir/list.txt"
