#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-interlaced-header
# @title: giftext interlaced header
# @description: Reads an interlaced GIF fixture with giftext and checks screen metadata.
# @timeout: 180
# @tags: usage, gif, metadata
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giftext-interlaced-header"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap-interlaced.gif"
validator_require_file "$gif"
giftext "$gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'
