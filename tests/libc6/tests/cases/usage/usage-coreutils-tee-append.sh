#!/usr/bin/env bash
# @testcase: usage-coreutils-tee-append
# @title: coreutils tee append
# @description: Appends two payloads to the same file via tee -a and verifies both records are preserved in order.
# @timeout: 180
# @tags: usage, coreutils, io
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-tee-append"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first\n' | tee "$tmpdir/log" >/dev/null
printf 'second\n' | tee -a "$tmpdir/log" >/dev/null

validator_assert_contains "$tmpdir/log" 'first'
validator_assert_contains "$tmpdir/log" 'second'

line_count=$(wc -l <"$tmpdir/log")
[[ "$line_count" -eq 2 ]] || { printf 'expected 2 lines, got %s\n' "$line_count" >&2; exit 1; }
