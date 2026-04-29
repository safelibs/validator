#!/usr/bin/env bash
# @testcase: usage-bzip2-decompress-suffix
# @title: bunzip2 strips suffix
# @description: Decompresses a .bz2 file in place with bunzip2 and verifies the suffixless file is restored.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-decompress-suffix"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'suffix payload\n' >"$tmpdir/name.txt"
bzip2 -c "$tmpdir/name.txt" >"$tmpdir/name.txt.bz2"
rm "$tmpdir/name.txt"
bunzip2 "$tmpdir/name.txt.bz2"
validator_assert_contains "$tmpdir/name.txt" 'suffix payload'
