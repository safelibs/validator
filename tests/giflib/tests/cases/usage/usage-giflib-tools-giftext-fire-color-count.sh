#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-fire-color-count
# @title: giftext fire color count
# @description: Dumps fire.gif colormap text with giftext and verifies numeric color table rows are present.
# @timeout: 180
# @tags: usage, gif, metadata
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giftext-fire-color-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"
giftext -c "$gif" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Global Color Map'
