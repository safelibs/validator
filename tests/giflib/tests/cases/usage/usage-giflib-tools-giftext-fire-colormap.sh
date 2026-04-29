#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-fire-colormap
# @title: giftext fire color map
# @description: Reads fire.gif with giftext color map output and checks palette metadata.
# @timeout: 180
# @tags: usage, gif, metadata
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giftext-fire-colormap"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"
giftext -c "$gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Global Color Map'
