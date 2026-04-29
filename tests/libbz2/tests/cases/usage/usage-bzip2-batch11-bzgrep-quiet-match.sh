#!/usr/bin/env bash
# @testcase: usage-bzip2-batch11-bzgrep-quiet-match
# @title: bzgrep quiet match
# @description: Searches compressed text with bzgrep -q and verifies the match is reported by exit status only.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-batch11-bzgrep-quiet-match"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'quiet needle\n' >"$tmpdir/plain.txt"
bzip2 -k "$tmpdir/plain.txt"
bzgrep -q 'needle' "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
test ! -s "$tmpdir/out"
