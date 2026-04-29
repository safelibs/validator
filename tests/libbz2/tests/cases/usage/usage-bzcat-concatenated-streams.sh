#!/usr/bin/env bash
# @testcase: usage-bzcat-concatenated-streams
# @title: bzcat concatenated streams
# @description: Concatenates two bzip2 streams and verifies bzcat expands both member payloads.
# @timeout: 180
# @tags: usage, bzip2, stream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzcat-concatenated-streams"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first\n' >"$tmpdir/first.txt"
printf 'second\n' >"$tmpdir/second.txt"
bzip2 -c "$tmpdir/first.txt" >"$tmpdir/first.bz2"
bzip2 -c "$tmpdir/second.txt" >"$tmpdir/second.bz2"
cat "$tmpdir/first.bz2" "$tmpdir/second.bz2" >"$tmpdir/combined.bz2"
bzcat "$tmpdir/combined.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'first'
validator_assert_contains "$tmpdir/out" 'second'
