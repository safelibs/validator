#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-concatenated-frames-decode
# @title: zstd CLI decodes concatenated raw frames (no tar)
# @description: Compresses two distinct payloads with the zstd CLI, concatenates the resulting raw .zst files into a single multi-frame stream, verifies both frames pass zstd -t and that zstd -d produces the byte-for-byte concatenation of the original payloads.
# @timeout: 180
# @tags: usage, archive, zstd, cli, multi-frame
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

a="$tmpdir/a.bin"
b="$tmpdir/b.bin"
printf 'frame-A payload first\n' >"$a"
printf 'frame-B payload second\n' >"$b"

zstd -q -o "$tmpdir/a.zst" "$a"
zstd -q -o "$tmpdir/b.zst" "$b"
validator_require_file "$tmpdir/a.zst"
validator_require_file "$tmpdir/b.zst"

magic_a=$(od -An -N4 -tx1 "$tmpdir/a.zst" | tr -d ' \n')
magic_b=$(od -An -N4 -tx1 "$tmpdir/b.zst" | tr -d ' \n')
test "$magic_a" = "28b52ffd"
test "$magic_b" = "28b52ffd"

# Concatenate the two raw zstd frames into one multi-frame stream.
cat "$tmpdir/a.zst" "$tmpdir/b.zst" >"$tmpdir/combined.zst"

# Both frames must validate.
zstd -tq "$tmpdir/combined.zst"

# zstd -d concatenates decoded frames.
zstd -dq -c "$tmpdir/combined.zst" >"$tmpdir/combined.bin"
cat "$a" "$b" >"$tmpdir/expected.bin"
cmp "$tmpdir/combined.bin" "$tmpdir/expected.bin"
