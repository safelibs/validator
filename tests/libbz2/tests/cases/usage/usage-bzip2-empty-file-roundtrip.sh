#!/usr/bin/env bash
# @testcase: usage-bzip2-empty-file-roundtrip
# @title: bzip2 empty file roundtrip
# @description: Compresses and decompresses an empty file with bzip2 and verifies that the restored output remains empty.
# @timeout: 180
# @tags: usage, bzip2, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-empty-file-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/empty.txt"
bzip2 -zk "$tmpdir/empty.txt"
bunzip2 -c "$tmpdir/empty.txt.bz2" >"$tmpdir/out"
test "$(wc -c <"$tmpdir/out")" -eq 0
