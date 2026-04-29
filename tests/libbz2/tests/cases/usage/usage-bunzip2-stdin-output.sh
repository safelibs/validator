#!/usr/bin/env bash
# @testcase: usage-bunzip2-stdin-output
# @title: bunzip2 stdin output
# @description: Exercises bunzip2 stdin output through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bunzip2-stdin-output"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample_root="$VALIDATOR_SAMPLE_ROOT"

cat "$sample_root/sample2.bz2" | bunzip2 -c >"$tmpdir/out.txt"
cmp "$sample_root/sample2.ref" "$tmpdir/out.txt"
