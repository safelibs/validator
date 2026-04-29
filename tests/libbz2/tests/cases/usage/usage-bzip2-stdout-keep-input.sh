#!/usr/bin/env bash
# @testcase: usage-bzip2-stdout-keep-input
# @title: bzip2 stdout keep input
# @description: Compresses a file to stdout with bzip2 -k, keeps the original input, and verifies both original and restored output content.
# @timeout: 180
# @tags: usage, bzip2, stream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-stdout-keep-input"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'stdout keep payload\n' >"$tmpdir/input.txt"
bzip2 -kc "$tmpdir/input.txt" >"$tmpdir/out.bz2"
validator_assert_contains "$tmpdir/input.txt" 'stdout keep payload'
bunzip2 -c "$tmpdir/out.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'stdout keep payload'
