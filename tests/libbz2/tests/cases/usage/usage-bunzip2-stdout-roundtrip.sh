#!/usr/bin/env bash
# @testcase: usage-bunzip2-stdout-roundtrip
# @title: bunzip2 stdout roundtrip
# @description: Decompresses a bzip2 stream to stdout with bunzip2 -c and verifies the restored plaintext payload.
# @timeout: 180
# @tags: usage, bzip2, stream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bunzip2-stdout-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'bunzip stdout payload\n' >"$tmpdir/input.txt"
bzip2 -zk "$tmpdir/input.txt"
bunzip2 -c "$tmpdir/input.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'bunzip stdout payload'
