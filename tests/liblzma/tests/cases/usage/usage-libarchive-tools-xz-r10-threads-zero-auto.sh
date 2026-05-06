#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r10-threads-zero-auto
# @title: xz -T0 auto-threaded encode round-trip
# @description: Encodes a tarball with xz -T0 (auto thread count) and round-trips it through bsdtar, asserting byte-identical content and a non-trivial xz --robot --list summary row.
# @timeout: 240
# @tags: usage, xz, threads
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
python3 -c 'import sys
for i in range(4096):
    sys.stdout.write("auto-threads row %05d alpha beta gamma delta epsilon zeta\n" % i)' \
  >"$tmpdir/in/payload.txt"
src_sha=$(sha256sum "$tmpdir/in/payload.txt" | awk '{print $1}')

bsdtar -cf "$tmpdir/plain.tar" -C "$tmpdir/in" payload.txt
xz -T 0 -c "$tmpdir/plain.tar" >"$tmpdir/a.tar.xz"

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

xz --robot --list "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
totals_files=$(awk '$1=="totals"{print $2}' "$tmpdir/list.txt")
test "$totals_files" = "1"

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
out_sha=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
