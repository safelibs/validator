#!/usr/bin/env bash
# @testcase: usage-bzip2-block-six-roundtrip
# @title: bzip2 block size six roundtrip
# @description: Compresses a multi-line payload with bzip2 -6, decompresses it through bzip2 -dc, and verifies byte-for-byte equality with the source.
# @timeout: 180
# @tags: usage, bzip2, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-block-six-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 64); do printf 'block six payload %02d\n' "$i"; done >"$tmpdir/in.txt"
bzip2 -6 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
bzip2 -dc "$tmpdir/in.txt.bz2" >"$tmpdir/out.txt"
cmp "$tmpdir/in.txt" "$tmpdir/out.txt"
