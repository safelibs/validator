#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch12-giftext-treescap-screen-size
# @title: giftext reports treescap screen size
# @description: Runs giftext on the treescap GIF and confirms the screen size header line is present in the output.
# @timeout: 60
# @tags: usage, cli, giftext
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/text.out"
validator_assert_contains "$tmpdir/text.out" 'Screen Size'
grep -E 'Screen Size.*[0-9]+' "$tmpdir/text.out"
