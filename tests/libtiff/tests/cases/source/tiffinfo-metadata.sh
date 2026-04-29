#!/usr/bin/env bash
# @testcase: tiffinfo-metadata
# @title: tiffinfo metadata inspection
# @description: Runs tiffinfo on a checked-in TIFF image and inspects dimensions.
# @timeout: 120
# @tags: cli, metadata

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

t="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"; validator_require_file "$t"; tiffinfo "$t" | tee "$tmpdir/info"; grep -Ei 'Image Width|Bits/Sample' "$tmpdir/info"
