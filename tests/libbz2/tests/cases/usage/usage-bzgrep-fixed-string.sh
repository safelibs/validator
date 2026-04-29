#!/usr/bin/env bash
# @testcase: usage-bzgrep-fixed-string
# @title: bzgrep fixed string
# @description: Searches compressed text with bzgrep fixed-string mode and verifies the matching line is returned.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-fixed-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nneedle\nbeta\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
bzgrep -F 'needle' "$tmpdir/in.txt.bz2" >"$tmpdir/out"
grep -Fxq 'needle' "$tmpdir/out"
