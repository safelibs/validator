#!/usr/bin/env bash
# @testcase: usage-bzip2-keep-input-compress
# @title: bzip2 keep input on compress
# @description: Exercises bzip2 keep input on compress through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-keep-input-compress"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample_root="$VALIDATOR_SAMPLE_ROOT"

printf 'keep input payload\n' >"$tmpdir/data.txt"
bzip2 -k "$tmpdir/data.txt"
validator_assert_contains "$tmpdir/data.txt" 'keep input payload'
bzip2 -dc "$tmpdir/data.txt.bz2" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'keep input payload'
