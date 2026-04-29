#!/usr/bin/env bash
# @testcase: usage-bzip2-recompress-file
# @title: bzip2 recompresses file
# @description: Decompresses and recompresses a payload through bzip2 and verifies the restored bytes match.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-recompress-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'recompress payload\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/one.bz2"
bunzip2 -c "$tmpdir/one.bz2" >"$tmpdir/plain.txt"
bzip2 -c "$tmpdir/plain.txt" >"$tmpdir/two.bz2"
cmp "$tmpdir/plain.txt" <(bzip2 -dc "$tmpdir/two.bz2")
