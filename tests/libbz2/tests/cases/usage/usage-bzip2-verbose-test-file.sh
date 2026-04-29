#!/usr/bin/env bash
# @testcase: usage-bzip2-verbose-test-file
# @title: bzip2 verbose test file
# @description: Exercises bzip2 verbose test file through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-verbose-test-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample_root="$VALIDATOR_SAMPLE_ROOT"

bzip2 -tv "$sample_root/sample1.bz2" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'ok'
