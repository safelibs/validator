#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r12-check-crc64-default
# @title: xz default --check is CRC64 on noble
# @description: Compresses a payload with no explicit --check flag and verifies "xz --robot --list" reports CRC64 as the default integrity-check column, then round-trips back to byte-equal output via xz -dc.
# @timeout: 60
# @tags: usage, xz, integrity
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'crc64 default check payload alpha beta gamma\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz -c "$tmpdir/in.txt" >"$tmpdir/out.xz"

xz --robot --list "$tmpdir/out.xz" >"$tmpdir/list.txt"
totals_check=$(awk '$1=="totals"{print $7}' "$tmpdir/list.txt")
test "$totals_check" = "CRC64"

xz -dc "$tmpdir/out.xz" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
