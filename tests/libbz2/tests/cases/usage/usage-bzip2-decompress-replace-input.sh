#!/usr/bin/env bash
# @testcase: usage-bzip2-decompress-replace-input
# @title: bzip2 decompress replaces compressed file
# @description: Compresses a file with bzip2, decompresses it with bzip2 -d, and verifies the .bz2 file is removed and the plaintext restored.
# @timeout: 180
# @tags: usage, bzip2, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-decompress-replace-input"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'replace input payload\n' >"$tmpdir/in.txt"
bzip2 "$tmpdir/in.txt"
test ! -e "$tmpdir/in.txt"
bzip2 -d "$tmpdir/in.txt.bz2"
validator_require_file "$tmpdir/in.txt"
test ! -e "$tmpdir/in.txt.bz2"
validator_assert_contains "$tmpdir/in.txt" 'replace input payload'
