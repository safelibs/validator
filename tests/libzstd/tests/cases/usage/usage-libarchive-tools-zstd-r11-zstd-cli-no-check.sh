#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r11-zstd-cli-no-check
# @title: zstd --no-check omits the frame checksum reported by --list
# @description: Compresses with --no-check and asserts the zstd --list summary reports Check column "None" instead of the default XXH64 trailer, while the output still round-trips on decode.
# @timeout: 60
# @tags: usage, zstd, cli, checksum
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'no-check payload bytes\n' >"$tmpdir/in.txt"

zstd --no-check -q "$tmpdir/in.txt" -o "$tmpdir/in.txt.zst"
zstd --list "$tmpdir/in.txt.zst" >"$tmpdir/listing"
grep -E '[[:space:]]None[[:space:]]+' "$tmpdir/listing" >/dev/null

zstd -d -q "$tmpdir/in.txt.zst" -o "$tmpdir/out.txt"
cmp "$tmpdir/in.txt" "$tmpdir/out.txt"
