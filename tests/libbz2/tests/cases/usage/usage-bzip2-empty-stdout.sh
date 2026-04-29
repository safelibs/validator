#!/usr/bin/env bash
# @testcase: usage-bzip2-empty-stdout
# @title: bzip2 empty stdout stream
# @description: Compresses and decompresses an empty file through stdout and verifies the reconstructed output is still empty.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-empty-stdout"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/empty.txt"
bzip2 -c "$tmpdir/empty.txt" >"$tmpdir/empty.txt.bz2"
bzip2 -dc "$tmpdir/empty.txt.bz2" >"$tmpdir/out.txt"
test "$(wc -c <"$tmpdir/out.txt")" -eq 0
