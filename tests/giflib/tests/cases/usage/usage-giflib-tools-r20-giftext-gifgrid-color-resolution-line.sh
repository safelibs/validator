#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r20-giftext-gifgrid-color-resolution-line
# @title: giftext on gifgrid.gif emits a "Color Resolution" line
# @description: Runs giftext on the gifgrid.gif fixture and asserts the produced report contains the literal substring "ColorResolution", exercising the textual color-resolution field rendering on the gifgrid fixture distinct from prior fire/treescap color resolution tests.
# @timeout: 60
# @tags: usage, cli, giftext, color-resolution, r20
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'ColorResolution'
