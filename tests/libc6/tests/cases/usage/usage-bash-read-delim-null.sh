#!/usr/bin/env bash
# @testcase: usage-bash-read-delim-null
# @title: bash read -d delimiter
# @description: Splits a NUL-delimited stream with bash read -d "" inside a while loop and verifies each record is captured intact.
# @timeout: 120
# @tags: usage, shell, libc
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-read-delim-null"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\0beta gamma\0delta\0' >"$tmpdir/in.bin"

bash -c '
count=0
while IFS= read -r -d "" rec; do
  printf "[%d]%s\n" "$count" "$rec"
  count=$((count + 1))
done <"$1"
printf "total=%d\n" "$count"
' _ "$tmpdir/in.bin" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" '[0]alpha'
validator_assert_contains "$tmpdir/out" '[1]beta gamma'
validator_assert_contains "$tmpdir/out" '[2]delta'
validator_assert_contains "$tmpdir/out" 'total=3'
