#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-ycbcr-positioning-batch11
# @title: exif machine YCbCrPositioning
# @description: Reads the YCbCrPositioning tag in machine-readable form with exif.
# @timeout: 180
# @tags: usage, exif, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-ycbcr-positioning-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=YCbCrPositioning "$img" >"$tmpdir/out"
test "$(wc -c <"$tmpdir/out")" -gt 0
