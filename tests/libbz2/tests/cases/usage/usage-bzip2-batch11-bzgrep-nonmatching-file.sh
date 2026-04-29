#!/usr/bin/env bash
# @testcase: usage-bzip2-batch11-bzgrep-nonmatching-file
# @title: bzgrep nonmatching file
# @description: Searches compressed files with bzgrep -L and verifies the nonmatching compressed filename is emitted.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-batch11-bzgrep-nonmatching-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'needle\n' >"$tmpdir/a.txt"
printf 'other\n' >"$tmpdir/b.txt"
bzip2 -k "$tmpdir/a.txt" "$tmpdir/b.txt"
bzgrep -L 'needle' "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'b.txt.bz2'
