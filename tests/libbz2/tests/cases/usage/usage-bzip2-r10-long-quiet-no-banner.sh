#!/usr/bin/env bash
# @testcase: usage-bzip2-r10-long-quiet-no-banner
# @title: bzip2 --quiet long flag suppresses noncritical messages
# @description: Compresses content with --quiet and verifies stderr is empty while the compressed file is still produced and round-trips cleanly.
# @timeout: 60
# @tags: usage, compression, long-flag
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'quiet long flag content\n' >"$tmpdir/in.txt"

bzip2 --quiet "$tmpdir/in.txt" 2>"$tmpdir/err"

stderr_size=$(stat -c '%s' "$tmpdir/err")
[[ "$stderr_size" == 0 ]]

[[ -f "$tmpdir/in.txt.bz2" ]]
bzip2 -dc "$tmpdir/in.txt.bz2" >"$tmpdir/round"
grep -Fq 'quiet long flag content' "$tmpdir/round"
