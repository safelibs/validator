#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-scene-capture
# @title: exif machine SceneCaptureType
# @description: Reads SceneCaptureType via exif --machine-readable and verifies that the Landscape scene capture type is reported.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-scene-capture"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=SceneCaptureType "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Landscape'
