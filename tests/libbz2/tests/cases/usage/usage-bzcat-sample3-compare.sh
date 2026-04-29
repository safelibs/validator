#!/usr/bin/env bash
# @testcase: usage-bzcat-sample3-compare
# @title: bzcat sample three compare
# @description: Exercises bzcat sample three compare through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzcat-sample3-compare"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample_root="$VALIDATOR_SAMPLE_ROOT"

bzcat "$sample_root/sample3.bz2" >"$tmpdir/out.txt"
cmp "$sample_root/sample3.ref" "$tmpdir/out.txt"
