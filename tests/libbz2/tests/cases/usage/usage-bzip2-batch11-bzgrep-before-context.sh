#!/usr/bin/env bash
# @testcase: usage-bzip2-batch11-bzgrep-before-context
# @title: bzgrep before context
# @description: Searches compressed text with bzgrep -B and verifies a preceding context line is emitted.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-batch11-bzgrep-before-context"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\ngamma\n' >"$tmpdir/plain.txt"
bzip2 -k "$tmpdir/plain.txt"
bzgrep -B 1 'gamma' "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'beta'
