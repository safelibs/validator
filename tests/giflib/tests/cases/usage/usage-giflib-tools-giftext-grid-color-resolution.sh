#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-grid-color-resolution
# @title: giftext grid color resolution
# @description: Dumps gifgrid.gif with giftext and verifies the color resolution field is present.
# @timeout: 180
# @tags: usage, gif, metadata
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giftext-grid-color-resolution"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"
giftext "$gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'ColorResolution'
