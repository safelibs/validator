#!/usr/bin/env bash
# @testcase: usage-bzless-decompresses-file
# @title: bzcat decompresses file to stdout
# @description: Decompresses a .bz2 file through bzcat (the pipeline-friendly pager-free counterpart of bzless) and verifies the plaintext lines round-trip on stdout.
# @timeout: 180
# @tags: usage, bzip2, pager
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzless-decompresses-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

command -v bzcat >/dev/null

printf 'bzless line one\nbzless line two\nbzless line three\n' >"$tmpdir/plain.txt"
bzip2 -k "$tmpdir/plain.txt"
bzcat "$tmpdir/plain.txt.bz2" >"$tmpdir/out" 2>"$tmpdir/err"

validator_assert_contains "$tmpdir/out" 'bzless line one'
validator_assert_contains "$tmpdir/out" 'bzless line two'
validator_assert_contains "$tmpdir/out" 'bzless line three'

# The decompressed bytes must exactly match the original plaintext.
cmp "$tmpdir/out" "$tmpdir/plain.txt"
