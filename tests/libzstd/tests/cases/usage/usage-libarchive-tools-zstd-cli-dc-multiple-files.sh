#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-dc-multiple-files
# @title: zstd CLI -dc decodes multiple files at once to stdout
# @description: Compresses three distinct payloads into independent .zst frames and then invokes 'zstd -dc a.zst b.zst c.zst' so the CLI decodes all three in a single command and concatenates them on stdout. Verifies that the concatenated stdout output matches the byte-for-byte concatenation of the original sources.
# @timeout: 180
# @tags: usage, archive, zstd, cli, multi-file
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

a="$tmpdir/a.bin"
b="$tmpdir/b.bin"
c="$tmpdir/c.bin"
printf 'first payload alpha\n' >"$a"
printf 'second payload beta\n' >"$b"
printf 'third payload gamma\n' >"$c"

zstd -q -o "$tmpdir/a.zst" "$a"
zstd -q -o "$tmpdir/b.zst" "$b"
zstd -q -o "$tmpdir/c.zst" "$c"
validator_require_file "$tmpdir/a.zst"
validator_require_file "$tmpdir/b.zst"
validator_require_file "$tmpdir/c.zst"

# zstd -dc on multiple inputs concatenates their decoded streams to stdout.
zstd -dq -c "$tmpdir/a.zst" "$tmpdir/b.zst" "$tmpdir/c.zst" >"$tmpdir/decoded.bin"

cat "$a" "$b" "$c" >"$tmpdir/expected.bin"
cmp "$tmpdir/decoded.bin" "$tmpdir/expected.bin"

# Sanity: each input must also pass independent integrity validation.
zstd -tq "$tmpdir/a.zst" "$tmpdir/b.zst" "$tmpdir/c.zst"
