#!/usr/bin/env bash
# @testcase: usage-bzgrep-search
# @title: bzgrep searches compressed data
# @description: Searches a compressed text file with bzgrep and checks the matching line.
# @timeout: 180
# @tags: usage, compression, search
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-search"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\ngamma\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
bzgrep '^beta$' "$tmpdir/in.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'beta'
