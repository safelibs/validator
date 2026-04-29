#!/usr/bin/env bash
# @testcase: usage-coreutils-wc-bytes
# @title: coreutils wc bytes
# @description: Counts file bytes with wc and verifies the exact byte count emitted by the client.
# @timeout: 180
# @tags: usage, coreutils, filesystem
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-wc-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'abcd' >"$tmpdir/input.txt"
wc -c <"$tmpdir/input.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '4'
