#!/usr/bin/env bash
# @testcase: usage-bzip2-stdout-space-file
# @title: bzip2 stdout spaced file
# @description: Compresses a spaced filename to stdout with bzip2 and verifies a later decompression round trip.
# @timeout: 180
# @tags: usage, bzip2, stream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-stdout-space-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'space stdout payload\n' >"$tmpdir/space name.txt"
bzip2 -c "$tmpdir/space name.txt" >"$tmpdir/out.bz2"
bunzip2 -c "$tmpdir/out.bz2" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'space stdout payload'
