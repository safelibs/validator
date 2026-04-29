#!/usr/bin/env bash
# @testcase: usage-bzip2-decompress-keep-input
# @title: bzip2 decompress keep input
# @description: Runs bunzip2 keep-input decompression and verifies the compressed file remains.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'bzip2 keep input payload\n' >"$tmpdir/expected"
bzip2 -c "$tmpdir/expected" >"$tmpdir/payload.bz2"

bunzip2 -k "$tmpdir/payload.bz2"

test -f "$tmpdir/payload.bz2"
test -f "$tmpdir/payload"
cmp "$tmpdir/expected" "$tmpdir/payload"
printf 'bzip2 decompress keep input ok\n'
