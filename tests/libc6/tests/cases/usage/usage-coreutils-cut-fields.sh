#!/usr/bin/env bash
# @testcase: usage-coreutils-cut-fields
# @title: coreutils cuts delimited fields
# @description: Extracts delimited columns with cut and verifies the selected field values are preserved.
# @timeout: 180
# @tags: usage, cli
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-cut-fields"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'name:score\nalpha:42\nbeta:7\n' >"$tmpdir/in.txt"
cut -d: -f2 "$tmpdir/in.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '42'
validator_assert_contains "$tmpdir/out" '7'
