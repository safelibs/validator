#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r12-cli-decompress-suffix-strip
# @title: zstd -d on file.zst writes the decoded output to file with the suffix stripped
# @description: Compresses an input named payload.bin to payload.bin.zst, removes the original, decodes with zstd -d, and asserts the recovered file is named payload.bin (the .zst suffix stripped) and matches the original byte stream.
# @timeout: 60
# @tags: usage, zstd, cli, decompress
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r12 suffix-strip payload row\n%.0s' {1..200} >"$tmpdir/payload.bin"
cp "$tmpdir/payload.bin" "$tmpdir/orig.bin"

zstd -q "$tmpdir/payload.bin" -o "$tmpdir/payload.bin.zst"
rm -f "$tmpdir/payload.bin"

# Decode without -o; zstd should derive the name by stripping .zst.
( cd "$tmpdir" && zstd -dq payload.bin.zst )

validator_require_file "$tmpdir/payload.bin"
cmp "$tmpdir/payload.bin" "$tmpdir/orig.bin"
