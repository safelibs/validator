#!/usr/bin/env bash
# @testcase: usage-bunzip2-alias
# @title: bunzip2 alias decompress
# @description: Decompresses a bzip2 stream with the bunzip2 alias and verifies the restored payload.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bunzip2-alias"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'bunzip2 payload\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
bunzip2 -c "$tmpdir/in.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'bunzip2 payload'
