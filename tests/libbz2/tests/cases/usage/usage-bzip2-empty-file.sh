#!/usr/bin/env bash
# @testcase: usage-bzip2-empty-file
# @title: bzip2 empty file round trip
# @description: Compresses and decompresses an empty file through bzip2 standard streams.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-empty-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/empty.txt"
bzip2 -c "$tmpdir/empty.txt" | bzip2 -dc >"$tmpdir/out"
test ! -s "$tmpdir/out"
