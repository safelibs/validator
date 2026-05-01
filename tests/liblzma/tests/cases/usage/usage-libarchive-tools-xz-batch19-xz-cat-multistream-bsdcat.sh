#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch19-xz-cat-multistream-bsdcat
# @title: bsdcat decodes concatenated raw .xz streams
# @description: Compresses two distinct payloads to separate .xz streams, concatenates them into one multi-stream .xz file, and confirms bsdcat emits the two original payloads back-to-back via liblzma's multi-stream support.
# @timeout: 180
# @tags: usage, xz, bsdcat, multistream
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'multistream first payload\n' >"$tmpdir/a.bin"
printf 'multistream second payload\n' >"$tmpdir/b.bin"

xz -z -c "$tmpdir/a.bin" >"$tmpdir/a.xz"
xz -z -c "$tmpdir/b.bin" >"$tmpdir/b.xz"

cat "$tmpdir/a.xz" "$tmpdir/b.xz" >"$tmpdir/multi.xz"

# Combined file still starts with .xz magic.
magic_hex=$(head -c 6 "$tmpdir/multi.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# xz --robot reports two streams.
xz --robot --list "$tmpdir/multi.xz" >"$tmpdir/robot.txt"
totals_streams=$(awk '$1=="totals"{print $2}' "$tmpdir/robot.txt")
test "$totals_streams" = "2"

# Build the expected concatenation explicitly and compare bsdcat's output.
cat "$tmpdir/a.bin" "$tmpdir/b.bin" >"$tmpdir/expected.bin"
bsdcat "$tmpdir/multi.xz" >"$tmpdir/out.bin"
cmp "$tmpdir/expected.bin" "$tmpdir/out.bin"

expected_sha=$(sha256sum "$tmpdir/expected.bin" | awk '{print $1}')
out_sha=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
test "$expected_sha" = "$out_sha"
