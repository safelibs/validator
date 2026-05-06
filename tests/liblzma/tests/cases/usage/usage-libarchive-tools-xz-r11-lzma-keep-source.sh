#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r11-lzma-keep-source
# @title: xz -F lzma --keep on a .lzma input preserves the source while emitting plain output
# @description: Round-trips a payload through legacy LZMA: encodes with -F lzma to .lzma, then decodes with --keep --decompress and verifies the original .lzma file remains and the decoded payload matches the source bytes.
# @timeout: 60
# @tags: usage, xz, lzma-legacy, keep
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'lzma keep source roundtrip alpha beta\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz -F lzma -c "$tmpdir/in.txt" >"$tmpdir/payload.lzma"
test -f "$tmpdir/payload.lzma"

xz -F lzma --keep --decompress "$tmpdir/payload.lzma"

# After --keep --decompress, both the .lzma source and the decoded plain file must exist.
test -f "$tmpdir/payload.lzma"
test -f "$tmpdir/payload"

out_sha=$(sha256sum "$tmpdir/payload" | awk '{print $1}')
test "$src_sha" = "$out_sha"
