#!/usr/bin/env bash
# @testcase: usage-coreutils-tr-squeeze-repeats
# @title: coreutils tr squeeze repeated characters
# @description: Uses tr -s to collapse runs of repeated characters into a single instance and verifies the output.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-tr-squeeze-repeats"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'aaabbbcccddd   end\n' | tr -s 'a-z ' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'abcd end'
