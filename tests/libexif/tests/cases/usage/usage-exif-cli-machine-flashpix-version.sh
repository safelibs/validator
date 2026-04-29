#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-flashpix-version
# @title: exif machine FlashPixVersion
# @description: Reads FlashPixVersion via exif --machine-readable and verifies that FlashPix Version 1.0 is reported.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-flashpix-version"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=FlashPixVersion "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'FlashPix Version 1.0'
