#!/usr/bin/env bash
# @testcase: usage-bzip2-batch11-bzgrep-no-filename
# @title: bzgrep no filename
# @description: Searches a single compressed file with bzgrep -h and checks bare matching lines.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-batch11-bzgrep-no-filename"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'needle one\nneedle two\n' >"$tmpdir/plain.txt"
bzip2 -k "$tmpdir/plain.txt"
bzgrep -h 'needle' "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
test "$(grep -c '^needle' "$tmpdir/out")" -eq 2
