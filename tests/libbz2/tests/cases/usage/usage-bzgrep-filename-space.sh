#!/usr/bin/env bash
# @testcase: usage-bzgrep-filename-space
# @title: bzgrep spaced filename search
# @description: Exercises bzgrep spaced filename search through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-filename-space"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample_root="$VALIDATOR_SAMPLE_ROOT"

printf 'space needle\n' >"$tmpdir/space name.txt"
bzip2 -c "$tmpdir/space name.txt" >"$tmpdir/space name.txt.bz2"
bzgrep -H 'needle' "$tmpdir/space name.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'space name.txt.bz2'
validator_assert_contains "$tmpdir/out" 'needle'
