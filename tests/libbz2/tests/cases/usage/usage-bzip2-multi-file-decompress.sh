#!/usr/bin/env bash
# @testcase: usage-bzip2-multi-file-decompress
# @title: bzip2 multi-file decompress
# @description: Decompresses two .bz2 files with bunzip2 in one invocation and verifies both restored payloads.
# @timeout: 180
# @tags: usage, bzip2, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-multi-file-decompress"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\n' >"$tmpdir/alpha.txt"
printf 'beta\n' >"$tmpdir/beta.txt"
bzip2 "$tmpdir/alpha.txt" "$tmpdir/beta.txt"
bunzip2 "$tmpdir/alpha.txt.bz2" "$tmpdir/beta.txt.bz2"
validator_assert_contains "$tmpdir/alpha.txt" 'alpha'
validator_assert_contains "$tmpdir/beta.txt" 'beta'
