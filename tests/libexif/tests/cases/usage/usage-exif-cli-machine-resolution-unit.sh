#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-resolution-unit
# @title: exif machine ResolutionUnit
# @description: Reads ResolutionUnit via exif --machine-readable and verifies that inch units are reported for the sample image.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-resolution-unit"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=ResolutionUnit "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Inch'
