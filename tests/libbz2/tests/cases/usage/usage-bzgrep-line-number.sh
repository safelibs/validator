#!/usr/bin/env bash
# @testcase: usage-bzgrep-line-number
# @title: bzgrep line number output
# @description: Searches a compressed file with bzgrep -n and verifies the matching line number is reported.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-line-number"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\ngamma\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
bzgrep -n '^beta$' "$tmpdir/in.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2:beta'
