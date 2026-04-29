#!/usr/bin/env bash
# @testcase: usage-bzip2-batch11-bzgrep-after-context
# @title: bzgrep after context
# @description: Searches compressed text with bzgrep -A and verifies a following context line is emitted.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-batch11-bzgrep-after-context"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\ngamma\n' >"$tmpdir/plain.txt"
bzip2 -k "$tmpdir/plain.txt"
bzgrep -A 1 'alpha' "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'beta'
