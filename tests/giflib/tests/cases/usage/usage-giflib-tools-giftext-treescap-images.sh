#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-treescap-images
# @title: giftext treescap image records
# @description: Reads treescap.gif with giftext and checks image descriptor output.
# @timeout: 180
# @tags: usage, gif, metadata
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giftext-treescap-images"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
giftext "$gif" | tee "$tmpdir/out"
grep -Eiq 'image' "$tmpdir/out"
