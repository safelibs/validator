#!/usr/bin/env bash
# @testcase: usage-gawk-assoc-array
# @title: gawk associative array
# @description: Aggregates repeated words with a gawk associative array and verifies the counter.
# @timeout: 180
# @tags: usage, text
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-assoc-array"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'red\nblue\nred\n' | gawk '{count[$1]++} END {print "red=" count["red"]}' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'red=2'
