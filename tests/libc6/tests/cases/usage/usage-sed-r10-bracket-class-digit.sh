#!/usr/bin/env bash
# @testcase: usage-sed-r10-bracket-class-digit
# @title: sed [[:digit:]] character class matches ASCII digits
# @description: Uses sed to replace runs of [[:digit:]] with N in a fixed input under LC_ALL=C and verifies only ASCII digits are collapsed (libc isdigit semantics).
# @timeout: 60
# @tags: usage, sed
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'abc123def4567ghi\n' >"$tmpdir/in.txt"
LC_ALL=C sed -E 's/[[:digit:]]+/N/g' "$tmpdir/in.txt" >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
[[ "$got" == "abcNdefNghi" ]]
