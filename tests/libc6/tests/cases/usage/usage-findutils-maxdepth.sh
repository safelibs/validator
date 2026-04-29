#!/usr/bin/env bash
# @testcase: usage-findutils-maxdepth
# @title: findutils maxdepth filter
# @description: Limits find traversal depth and verifies deeper files are excluded from the result set.
# @timeout: 180
# @tags: usage, filesystem
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-maxdepth"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/root/child/grand"
printf 'top\n' >"$tmpdir/root/top.txt"
printf 'nested\n' >"$tmpdir/root/child/nested.txt"
find "$tmpdir/root" -maxdepth 1 -type f -printf '%f\n' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'top.txt'
if grep -Fq 'nested.txt' "$tmpdir/out"; then exit 1; fi
