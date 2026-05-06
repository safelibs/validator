#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r11-check-sha256-integrity
# @title: xz --check=sha256 records SHA-256 integrity in the .xz stream
# @description: Compresses a payload with --check=sha256 and verifies "xz --robot --list" reports the integrity-check column as "SHA-256" while the round-trip decompresses to byte-equal output.
# @timeout: 60
# @tags: usage, xz, integrity
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import sys
for i in range(256):
    sys.stdout.write("sha256 row %03d alpha\n" % i)' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz --check=sha256 -c "$tmpdir/in.txt" >"$tmpdir/out.xz"

xz --robot --list "$tmpdir/out.xz" >"$tmpdir/list.txt"
totals_check=$(awk '$1=="totals"{print $7}' "$tmpdir/list.txt")
test "$totals_check" = "SHA-256"

xz -dc "$tmpdir/out.xz" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
