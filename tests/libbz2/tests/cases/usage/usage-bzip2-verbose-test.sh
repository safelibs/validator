#!/usr/bin/env bash
# @testcase: usage-bzip2-verbose-test
# @title: bzip2 verbose integrity check
# @description: Runs a verbose bzip2 integrity check on a generated compressed stream.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-verbose-test"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'verbose integrity payload\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
bzip2 -tvv "$tmpdir/in.txt.bz2" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'ok'
