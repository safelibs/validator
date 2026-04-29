#!/usr/bin/env bash
# @testcase: usage-bzcat-stdin-input
# @title: bzcat stdin input
# @description: Pipes a bzip2 stream into bzcat from stdin and verifies the decompressed payload appears on stdout.
# @timeout: 180
# @tags: usage, bzip2, stream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzcat-stdin-input"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'bzcat stdin payload\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"
bzcat <"$tmpdir/in.bz2" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'bzcat stdin payload'
