#!/usr/bin/env bash
# @testcase: usage-bzip2-batch12-bzcat-mixed-with-uncompressed-fails
# @title: bzcat on a non-bzip2 file exits nonzero
# @description: Runs bzcat against a plain text file that is not bzip2 compressed and verifies it exits with a non-zero status.
# @timeout: 60
# @tags: usage, compression, error
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'this is plain text, not bzip2\n' >"$tmpdir/plain.txt"

set +e
bzcat "$tmpdir/plain.txt" >"$tmpdir/out" 2>"$tmpdir/err"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
