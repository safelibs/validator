#!/usr/bin/env bash
# @testcase: usage-bzip2-fast-stdout
# @title: bzip2 fast stdout stream
# @description: Compresses data with the fastest bzip2 level and verifies stdout decompression.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-fast-stdout"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 40); do printf 'fast compression payload %02d\n' "$i"; done >"$tmpdir/in.txt"
bzip2 -1 -c "$tmpdir/in.txt" | bzip2 -dc >"$tmpdir/out"
cmp "$tmpdir/in.txt" "$tmpdir/out"
