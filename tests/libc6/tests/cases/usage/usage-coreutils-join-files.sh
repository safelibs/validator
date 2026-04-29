#!/usr/bin/env bash
# @testcase: usage-coreutils-join-files
# @title: coreutils joins files
# @description: Joins two sorted text files on a shared key with join and verifies the merged rows.
# @timeout: 180
# @tags: usage, cli
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-join-files"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '1 alpha\n2 beta\n' >"$tmpdir/left.txt"
printf '1 one\n2 two\n' >"$tmpdir/right.txt"
join "$tmpdir/left.txt" "$tmpdir/right.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '1 alpha one'
validator_assert_contains "$tmpdir/out" '2 beta two'
