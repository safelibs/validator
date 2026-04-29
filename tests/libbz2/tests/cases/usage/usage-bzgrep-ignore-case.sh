#!/usr/bin/env bash
# @testcase: usage-bzgrep-ignore-case
# @title: bzgrep ignore case search
# @description: Exercises bzgrep ignore case search through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-ignore-case"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample_root="$VALIDATOR_SAMPLE_ROOT"

printf 'Alpha\nneedle\nBETA\n' >"$tmpdir/input.txt"
bzip2 -c "$tmpdir/input.txt" >"$tmpdir/input.txt.bz2"
bzgrep -i 'beta' "$tmpdir/input.txt.bz2" >"$tmpdir/out"
grep -Fxq 'BETA' "$tmpdir/out"
