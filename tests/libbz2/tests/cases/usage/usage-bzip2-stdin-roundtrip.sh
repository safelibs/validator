#!/usr/bin/env bash
# @testcase: usage-bzip2-stdin-roundtrip
# @title: bzip2 stdin roundtrip
# @description: Compresses stdin with bzip2, decompresses the resulting stream, and verifies the restored plaintext payload.
# @timeout: 180
# @tags: usage, bzip2, stream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-stdin-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'stdin payload\n' | bzip2 -c >"$tmpdir/out.bz2"
bunzip2 -c "$tmpdir/out.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'stdin payload'
