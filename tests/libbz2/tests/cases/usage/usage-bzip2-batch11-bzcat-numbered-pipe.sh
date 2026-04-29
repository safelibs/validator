#!/usr/bin/env bash
# @testcase: usage-bzip2-batch11-bzcat-numbered-pipe
# @title: bzcat numbered pipe
# @description: Streams bzcat output through a numbering pipeline and checks decompressed lines.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-batch11-bzcat-numbered-pipe"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first\nsecond\n' >"$tmpdir/plain.txt"
bzip2 -k "$tmpdir/plain.txt"
bzcat "$tmpdir/plain.txt.bz2" | nl -ba >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '1'
validator_assert_contains "$tmpdir/out" 'second'
