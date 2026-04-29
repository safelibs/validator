#!/usr/bin/env bash
# @testcase: usage-bzip2-stdin-file-output
# @title: bzip2 stdin file output
# @description: Exercises bzip2 stdin file output through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-stdin-file-output"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample_root="$VALIDATOR_SAMPLE_ROOT"

printf 'stdin file output payload\n' | bzip2 -c >"$tmpdir/stdin.bz2"
bzip2 -dc "$tmpdir/stdin.bz2" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'stdin file output payload'
