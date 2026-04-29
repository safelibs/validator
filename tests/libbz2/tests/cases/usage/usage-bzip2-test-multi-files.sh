#!/usr/bin/env bash
# @testcase: usage-bzip2-test-multi-files
# @title: bzip2 test multiple files
# @description: Runs bzip2 -t on two compressed files in a single invocation and verifies both pass the integrity check.
# @timeout: 180
# @tags: usage, bzip2, integrity
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-test-multi-files"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first stream\n' >"$tmpdir/one.txt"
printf 'second stream\n' >"$tmpdir/two.txt"
bzip2 -k "$tmpdir/one.txt" "$tmpdir/two.txt"
bzip2 -t "$tmpdir/one.txt.bz2" "$tmpdir/two.txt.bz2"
