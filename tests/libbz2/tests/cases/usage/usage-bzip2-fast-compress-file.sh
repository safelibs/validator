#!/usr/bin/env bash
# @testcase: usage-bzip2-fast-compress-file
# @title: bzip2 fast compression file
# @description: Compresses a file at the fastest bzip2 block setting and verifies decompression restores the original payload.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-fast-compress-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'fast compression payload\n%.0s' $(seq 1 32) >"$tmpdir/in.txt"
cp "$tmpdir/in.txt" "$tmpdir/fast.txt"
bzip2 -1 "$tmpdir/fast.txt"
bzip2 -dc "$tmpdir/fast.txt.bz2" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'fast compression payload'
