#!/usr/bin/env bash
# @testcase: usage-bzip2-test-verbose-perfect-file
# @title: bzip2 -tv reports ok on perfect file
# @description: Runs bzip2 -tv against a freshly compressed valid stream and verifies the verbose report names the file and reports ok.
# @timeout: 180
# @tags: usage, bzip2, integrity
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-test-verbose-perfect-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'perfect verbose payload line one\nperfect verbose payload line two\n' >"$tmpdir/perfect.txt"
bzip2 -zk "$tmpdir/perfect.txt"
validator_require_file "$tmpdir/perfect.txt.bz2"

bzip2 -tv "$tmpdir/perfect.txt.bz2" >"$tmpdir/out" 2>"$tmpdir/err"
test ! -s "$tmpdir/out"
test -s "$tmpdir/err"
validator_assert_contains "$tmpdir/err" 'perfect.txt.bz2'
validator_assert_contains "$tmpdir/err" 'ok'
