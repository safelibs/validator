#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-fire-image-count
# @title: giftext fire image count
# @description: Dumps fire.gif with giftext and verifies image records are reported in the textual metadata output.
# @timeout: 180
# @tags: usage, gif, metadata
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giftext-fire-image-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"
giftext "$gif" | tee "$tmpdir/out"
grep -Eiq 'image|Image' "$tmpdir/out"
