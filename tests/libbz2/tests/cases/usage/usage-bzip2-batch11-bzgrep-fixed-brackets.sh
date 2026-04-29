#!/usr/bin/env bash
# @testcase: usage-bzip2-batch11-bzgrep-fixed-brackets
# @title: bzgrep fixed brackets
# @description: Searches literal bracket text in a compressed file with bzgrep -F.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-batch11-bzgrep-fixed-brackets"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '[literal]\nregex\n' >"$tmpdir/plain.txt"
bzip2 -k "$tmpdir/plain.txt"
bzgrep -F '[literal]' "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '[literal]'
