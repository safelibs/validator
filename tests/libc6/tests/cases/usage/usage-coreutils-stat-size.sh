#!/usr/bin/env bash
# @testcase: usage-coreutils-stat-size
# @title: coreutils stat size
# @description: Reads file size metadata with GNU stat and checks the reported byte count.
# @timeout: 180
# @tags: usage, coreutils, filesystem
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-stat-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '1234567890' >"$tmpdir/file.txt"
stat -c 'size=%s' "$tmpdir/file.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'size=10'
