#!/usr/bin/env bash
# @testcase: usage-bzip2-decompress-quiet-stdin
# @title: bzip2 quiet decompress stdin
# @description: Decompresses a bzip2 stream from stdin with bzip2 -dcq and verifies the restored payload is written to stdout.
# @timeout: 180
# @tags: usage, bzip2, stream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-decompress-quiet-stdin"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'quiet decompress payload\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"
bzip2 -dcq <"$tmpdir/in.bz2" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'quiet decompress payload'
