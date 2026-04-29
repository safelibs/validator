#!/usr/bin/env bash
# @testcase: usage-bunzip2-stdout-sample1
# @title: bunzip2 stdout sample1
# @description: Decompresses the bundled sample1 fixture to stdout with bunzip2 and verifies byte-for-byte parity with the reference file.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bunzip2-stdout-sample1"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

validator_require_file "$VALIDATOR_SAMPLE_ROOT/sample1.bz2"
validator_require_file "$VALIDATOR_SAMPLE_ROOT/sample1.ref"
bunzip2 -c "$VALIDATOR_SAMPLE_ROOT/sample1.bz2" >"$tmpdir/out.txt"
cmp "$VALIDATOR_SAMPLE_ROOT/sample1.ref" "$tmpdir/out.txt"
