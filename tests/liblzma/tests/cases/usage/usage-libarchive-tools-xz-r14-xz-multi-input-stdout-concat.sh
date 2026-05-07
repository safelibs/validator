#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r14-xz-multi-input-stdout-concat
# @title: xz -dc concatenates two .xz inputs to a single stdout stream
# @description: Compresses two distinct payloads into separate .xz files, then runs "xz -dc fileA.xz fileB.xz" with both files as positional args and asserts stdout equals the in-order byte concatenation of payloadA and payloadB, exercising xz's multi-file decompress-to-stdout concatenation.
# @timeout: 60
# @tags: usage, xz, multi-input, stdout
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'concat-alpha payload one\n' >"$tmpdir/a.txt"
printf 'concat-beta payload two longer\n' >"$tmpdir/b.txt"

xz -c "$tmpdir/a.txt" >"$tmpdir/a.xz"
xz -c "$tmpdir/b.txt" >"$tmpdir/b.xz"

cat "$tmpdir/a.txt" "$tmpdir/b.txt" >"$tmpdir/expected.txt"
expected_sha=$(sha256sum "$tmpdir/expected.txt" | awk '{print $1}')

xz -dc "$tmpdir/a.xz" "$tmpdir/b.xz" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')

test "$expected_sha" = "$out_sha"
