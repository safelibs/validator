#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-fire-planar
# @title: gif2rgb fire planar output
# @description: Converts fire.gif to planar RGB files and verifies each channel file exists.
# @timeout: 180
# @tags: usage, gif, conversion
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-fire-planar"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"
gif2rgb -o "$tmpdir/fire" "$gif"
validator_require_file "$tmpdir/fire.R"
validator_require_file "$tmpdir/fire.G"
validator_require_file "$tmpdir/fire.B"
