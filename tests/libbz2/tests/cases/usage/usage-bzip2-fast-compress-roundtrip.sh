#!/usr/bin/env bash
# @testcase: usage-bzip2-fast-compress-roundtrip
# @title: bzip2 fast compress roundtrip
# @description: Compresses a file with bzip2 -1, decompresses it again, and verifies the restored plaintext payload.
# @timeout: 180
# @tags: usage, bzip2, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-fast-compress-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'fast compression payload\n' >"$tmpdir/input.txt"
bzip2 -1k "$tmpdir/input.txt"
bunzip2 -c "$tmpdir/input.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'fast compression payload'
