#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r15-xzcat-three-files-stdout-concat
# @title: xzcat decodes three .xz inputs in one call and concatenates them to stdout
# @description: Compresses three distinct payloads to .xz files, runs "xzcat a.xz b.xz c.xz" with all three files as positional arguments, and asserts stdout matches the sha256 of the in-order concatenation of the three sources — exercising the multi-file decompress-to-stdout path through xzcat (distinct from r14 xz-multi-input-stdout-concat which uses xz -dc with two files).
# @timeout: 60
# @tags: usage, xzcat, multi-file, stdout
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r15 xzcat-concat-1\n' >"$tmpdir/p1.txt"
printf 'r15 xzcat-concat-2 longer payload\n' >"$tmpdir/p2.txt"
printf 'r15 xzcat-concat-3 final piece\n' >"$tmpdir/p3.txt"

xz -c "$tmpdir/p1.txt" >"$tmpdir/p1.xz"
xz -c "$tmpdir/p2.txt" >"$tmpdir/p2.xz"
xz -c "$tmpdir/p3.txt" >"$tmpdir/p3.xz"

cat "$tmpdir/p1.txt" "$tmpdir/p2.txt" "$tmpdir/p3.txt" >"$tmpdir/expected.txt"
expected_sha=$(sha256sum "$tmpdir/expected.txt" | awk '{print $1}')

xzcat "$tmpdir/p1.xz" "$tmpdir/p2.xz" "$tmpdir/p3.xz" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$expected_sha" = "$out_sha"
