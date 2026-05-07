#!/usr/bin/env bash
# @testcase: usage-exif-r13-cli-xml-output-canon-powershot-model
# @title: exif --xml-output emits <Model>Canon PowerShot S70</Model> for the canon fixture
# @description: Runs exif --xml-output against the canon fixture and verifies the resulting stream contains the exact substring "<Model>Canon PowerShot S70</Model>", asserting libexif emits a "Model" XML element (not "Make" / "Manufacturer") with both opening and closing tags around the Canon model string.
# @timeout: 60
# @tags: usage, xml-output, model
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/xml.out"
validator_assert_contains "$tmpdir/xml.out" "<Model>Canon PowerShot S70</Model>"
