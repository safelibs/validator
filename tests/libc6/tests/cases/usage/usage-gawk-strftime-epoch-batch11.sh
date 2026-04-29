#!/usr/bin/env bash
# @testcase: usage-gawk-strftime-epoch-batch11
# @title: gawk strftime epoch
# @description: Formats the Unix epoch through gawk strftime using libc time handling.
# @timeout: 180
# @tags: usage, gawk, time
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-strftime-epoch-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

TZ=UTC gawk 'BEGIN { print strftime("%Y-%m-%d", 0) }' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '1970-01-01'
