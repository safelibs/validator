#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-metering-mode
# @title: exif machine MeteringMode
# @description: Reads MeteringMode via exif --machine-readable and verifies that the Pattern metering mode is reported.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-metering-mode"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=MeteringMode "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Pattern'
