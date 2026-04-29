#!/usr/bin/env bash
# @testcase: tiffcp-copy
# @title: tiffcp copy behavior
# @description: Copies a TIFF fixture and confirms the copied image remains readable.
# @timeout: 120
# @tags: cli, media

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

t="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"; validator_require_file "$t"; tiffcp -c none "$t" "$tmpdir/copy.tiff"; tiffinfo "$tmpdir/copy.tiff" | tee "$tmpdir/info"; grep -Ei 'Image Width' "$tmpdir/info"
