#!/usr/bin/env bash
# @testcase: usage-bzip2-best-compress-roundtrip
# @title: bzip2 best compress roundtrip
# @description: Compresses a file with bzip2 -9, decompresses it again, and verifies the restored plaintext payload.
# @timeout: 180
# @tags: usage, bzip2, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-best-compress-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'best compression payload\n' >"$tmpdir/input.txt"
bzip2 -9k "$tmpdir/input.txt"
bunzip2 -c "$tmpdir/input.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'best compression payload'
