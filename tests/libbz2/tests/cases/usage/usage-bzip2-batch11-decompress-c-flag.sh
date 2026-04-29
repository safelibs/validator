#!/usr/bin/env bash
# @testcase: usage-bzip2-batch11-decompress-c-flag
# @title: bzip2 decompress c flag
# @description: Decompresses a bzip2 stream to stdout with the combined -dc flags.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-batch11-decompress-c-flag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'decompress c flag\n' >"$tmpdir/plain.txt"
bzip2 -k "$tmpdir/plain.txt"
bzip2 -dc "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'decompress c flag'
