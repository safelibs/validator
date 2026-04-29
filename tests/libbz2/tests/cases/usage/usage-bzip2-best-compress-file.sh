#!/usr/bin/env bash
# @testcase: usage-bzip2-best-compress-file
# @title: bzip2 best compression file
# @description: Compresses a file at the highest bzip2 block setting and verifies decompression restores the original payload.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-best-compress-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'best compression payload\n%.0s' $(seq 1 32) >"$tmpdir/in.txt"
cp "$tmpdir/in.txt" "$tmpdir/best.txt"
bzip2 -9 "$tmpdir/best.txt"
bzip2 -dc "$tmpdir/best.txt.bz2" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'best compression payload'
