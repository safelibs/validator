#!/usr/bin/env bash
# @testcase: usage-bzcat-alias
# @title: bzcat reads compressed data
# @description: Reads a bzip2 stream through the bzcat client alias and verifies output.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzcat-alias"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'bzcat payload\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
bzcat "$tmpdir/in.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'bzcat payload'
