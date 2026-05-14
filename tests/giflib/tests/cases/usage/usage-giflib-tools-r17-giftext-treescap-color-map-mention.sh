#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r17-giftext-treescap-color-map-mention
# @title: giftext on treescap.gif mentions a Color Map entry
# @description: Runs giftext on treescap.gif and asserts the rendered report contains the literal substring "Color Map", exercising the palette section emission distinct from per-image and screen-size sections.
# @timeout: 60
# @tags: usage, cli, giftext, palette
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Color Map'
