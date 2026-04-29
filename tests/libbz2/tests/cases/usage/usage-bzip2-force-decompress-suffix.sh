#!/usr/bin/env bash
# @testcase: usage-bzip2-force-decompress-suffix
# @title: bzip2 force decompress over existing file
# @description: Uses bzip2 -df to overwrite a pre-existing file when decompressing a .bz2 archive and verifies the restored content.
# @timeout: 180
# @tags: usage, bzip2, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-force-decompress-suffix"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'force suffix payload\n' >"$tmpdir/in.txt"
bzip2 "$tmpdir/in.txt"
cp "$tmpdir/in.txt.bz2" "$tmpdir/in.txt"
bzip2 -df "$tmpdir/in.txt.bz2"
validator_assert_contains "$tmpdir/in.txt" 'force suffix payload'
