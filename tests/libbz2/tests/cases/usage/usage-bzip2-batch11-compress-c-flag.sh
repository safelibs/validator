#!/usr/bin/env bash
# @testcase: usage-bzip2-batch11-compress-c-flag
# @title: bzip2 compress c flag
# @description: Compresses a file to stdout with -c and verifies decompression.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-batch11-compress-c-flag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'compress c flag\n' >"$tmpdir/plain.txt"
bzip2 -c "$tmpdir/plain.txt" >"$tmpdir/plain.bz2"
bunzip2 -c "$tmpdir/plain.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'compress c flag'
