#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r11-zstd-cli-rsyncable
# @title: zstd --rsyncable produces a valid stream that round-trips
# @description: Compresses 64 KiB of random bytes with the zstd CLI in --rsyncable mode and verifies the resulting frame passes integrity check (zstd -t) and decompresses byte-equal to the input.
# @timeout: 120
# @tags: usage, zstd, cli, rsyncable
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

head -c 65536 /dev/urandom >"$tmpdir/in.bin"
zstd --rsyncable -q "$tmpdir/in.bin" -o "$tmpdir/in.bin.zst"

zstd -t "$tmpdir/in.bin.zst"

zstd -d -q "$tmpdir/in.bin.zst" -o "$tmpdir/out.bin"
cmp "$tmpdir/in.bin" "$tmpdir/out.bin"
