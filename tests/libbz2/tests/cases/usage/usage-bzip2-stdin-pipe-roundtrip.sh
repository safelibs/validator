#!/usr/bin/env bash
# @testcase: usage-bzip2-stdin-pipe-roundtrip
# @title: bzip2 pipeline roundtrip
# @description: Pipes bzip2 -c output directly into bzip2 -dc and verifies the round-tripped payload matches the source byte-for-byte.
# @timeout: 180
# @tags: usage, bzip2, stream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-stdin-pipe-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'pipeline payload one\n' >"$tmpdir/a.txt"
bzip2 -c "$tmpdir/a.txt" | bzip2 -dc >"$tmpdir/out.txt"
cmp "$tmpdir/a.txt" "$tmpdir/out.txt"
