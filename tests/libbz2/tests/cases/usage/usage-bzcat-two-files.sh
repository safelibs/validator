#!/usr/bin/env bash
# @testcase: usage-bzcat-two-files
# @title: bzcat two files
# @description: Concatenates two compressed files with bzcat and verifies both decompressed payloads appear in the output.
# @timeout: 180
# @tags: usage, bzip2, stream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzcat-two-files"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first\n' >"$tmpdir/one.txt"
printf 'second\n' >"$tmpdir/two.txt"
bzip2 -zk "$tmpdir/one.txt"
bzip2 -zk "$tmpdir/two.txt"
bzcat "$tmpdir/one.txt.bz2" "$tmpdir/two.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'first'
validator_assert_contains "$tmpdir/out" 'second'
