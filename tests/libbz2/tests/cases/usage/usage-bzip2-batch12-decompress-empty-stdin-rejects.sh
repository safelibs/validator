#!/usr/bin/env bash
# @testcase: usage-bzip2-batch12-decompress-empty-stdin-rejects
# @title: bzip2 -d on empty stdin exits nonzero
# @description: Pipes zero bytes (empty file) into "bzip2 -d" and verifies bzip2 reports a non-zero exit code (a 0-byte stream is not a valid bzip2 archive).
# @timeout: 60
# @tags: usage, compression, error
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/empty"
[[ "$(stat -c '%s' "$tmpdir/empty")" == 0 ]]

set +e
bzip2 -dc <"$tmpdir/empty" >"$tmpdir/out" 2>"$tmpdir/err"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
