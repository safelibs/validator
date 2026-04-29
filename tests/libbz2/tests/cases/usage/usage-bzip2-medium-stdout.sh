#!/usr/bin/env bash
# @testcase: usage-bzip2-medium-stdout
# @title: bzip2 medium block stdout
# @description: Uses a medium bzip2 block size over stdout and verifies decompressed output matches.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-medium-stdout"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 20); do printf 'medium compression payload %02d\n' "$i"; done >"$tmpdir/in.txt"
bzip2 -7 -c "$tmpdir/in.txt" | bzip2 -dc >"$tmpdir/out"
cmp "$tmpdir/in.txt" "$tmpdir/out"
