#!/usr/bin/env bash
# @testcase: usage-bzip2-space-filename-decompress
# @title: bzip2 space filename decompress
# @description: Decompresses a spaced filename with bunzip2 and verifies the restored payload.
# @timeout: 180
# @tags: usage, bzip2, filesystem
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-space-filename-decompress"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'space payload\n' >"$tmpdir/space name.txt"
bzip2 "$tmpdir/space name.txt"
bunzip2 "$tmpdir/space name.txt.bz2"
validator_assert_contains "$tmpdir/space name.txt" 'space payload'
