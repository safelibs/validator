#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-treescap
# @title: giffix treescap copy
# @description: Runs giffix on treescap.gif and verifies the repaired stream is readable.
# @timeout: 180
# @tags: usage, gif, repair
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giffix-treescap"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
giffix "$gif" >"$tmpdir/fixed.gif"
giftext "$tmpdir/fixed.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'
