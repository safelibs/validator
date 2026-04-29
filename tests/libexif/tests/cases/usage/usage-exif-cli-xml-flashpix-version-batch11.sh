#!/usr/bin/env bash
# @testcase: usage-exif-cli-xml-flashpix-version-batch11
# @title: exif XML FlashPixVersion
# @description: Emits XML metadata with exif and checks the FlashPixVersion element.
# @timeout: 180
# @tags: usage, exif, metadata, xml
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-xml-flashpix-version-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '<FlashPixVersion>'
