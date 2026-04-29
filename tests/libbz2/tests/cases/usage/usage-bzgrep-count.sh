#!/usr/bin/env bash
# @testcase: usage-bzgrep-count
# @title: bzgrep count matches
# @description: Counts compressed-text matches with bzgrep and verifies the reported total.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'match\nskip\nmatch\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
bzgrep -c 'match' "$tmpdir/in.txt.bz2" >"$tmpdir/out"
grep -Fxq '2' "$tmpdir/out"
