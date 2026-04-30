#!/usr/bin/env bash
# @testcase: usage-bzip2-tiny-input-roundtrip
# @title: bzip2 round-trip on single-byte input
# @description: Compresses and decompresses a one-byte payload and verifies bytes match exactly through libbz2.
# @timeout: 60
# @tags: usage, compression, edge
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'A' >"$tmpdir/tiny.txt"
[[ $(wc -c <"$tmpdir/tiny.txt") -eq 1 ]]

bzip2 -c "$tmpdir/tiny.txt" >"$tmpdir/tiny.bz2"
# Header must still appear even for a one-byte input.
[[ $(head -c 3 "$tmpdir/tiny.bz2") == "BZh" ]]

bzip2 -dc "$tmpdir/tiny.bz2" >"$tmpdir/out"
cmp "$tmpdir/tiny.txt" "$tmpdir/out"
[[ $(wc -c <"$tmpdir/out") -eq 1 ]]
[[ $(cat "$tmpdir/out") == "A" ]]
