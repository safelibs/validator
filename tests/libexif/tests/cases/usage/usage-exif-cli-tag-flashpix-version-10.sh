#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-flashpix-version-10
# @title: exif tag FlashPixVersion 1.0
# @description: Reads the FlashPixVersion EXIF tag with the exif client and verifies that FlashPix Version 1.0 is reported.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="usage-exif-cli-tag-flashpix-version-10"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=FlashPixVersion "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'FlashPix Version 1.0'
