#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r12-xzcat-multi-file-concat
# @title: xzcat with two .xz file arguments concatenates decoded output
# @description: Compresses two distinct payloads to separate .xz files and runs "xzcat a.xz b.xz", asserting the stdout output is the in-order concatenation of both source payloads.
# @timeout: 60
# @tags: usage, xz, xzcat, multi-file
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first-xzcat-payload\n' >"$tmpdir/a.txt"
printf 'second-xzcat-payload\n' >"$tmpdir/b.txt"

xz -c "$tmpdir/a.txt" >"$tmpdir/a.xz"
xz -c "$tmpdir/b.txt" >"$tmpdir/b.xz"

cat "$tmpdir/a.txt" "$tmpdir/b.txt" >"$tmpdir/expected.txt"
expected_sha=$(sha256sum "$tmpdir/expected.txt" | awk '{print $1}')

xzcat "$tmpdir/a.xz" "$tmpdir/b.xz" >"$tmpdir/out.txt"
out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$expected_sha" = "$out_sha"
