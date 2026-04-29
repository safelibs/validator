#!/usr/bin/env bash
# @testcase: usage-bzcat-sample2-lines
# @title: bzcat sample2 lines
# @description: Streams the bundled sample2 fixture through bzcat and verifies the decompressed text is nonempty.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzcat-sample2-lines"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

validator_require_file "$VALIDATOR_SAMPLE_ROOT/sample2.bz2"
bzcat "$VALIDATOR_SAMPLE_ROOT/sample2.bz2" >"$tmpdir/out.txt"
test "$(wc -l <"$tmpdir/out.txt")" -gt 0
