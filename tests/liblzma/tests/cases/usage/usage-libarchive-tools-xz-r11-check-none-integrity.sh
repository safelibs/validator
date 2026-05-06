#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r11-check-none-integrity
# @title: xz --check=none records None integrity in the .xz stream
# @description: Compresses a payload with --check=none and verifies "xz --robot --list" reports the integrity-check column as "None" while the round-trip still decompresses to byte-equal output.
# @timeout: 60
# @tags: usage, xz, integrity
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'no integrity check payload alpha beta gamma\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz --check=none -c "$tmpdir/in.txt" >"$tmpdir/out.xz"

xz --robot --list "$tmpdir/out.xz" >"$tmpdir/list.txt"
totals_check=$(awk '$1=="totals"{print $7}' "$tmpdir/list.txt")
test "$totals_check" = "None"

xz -dc "$tmpdir/out.xz" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
