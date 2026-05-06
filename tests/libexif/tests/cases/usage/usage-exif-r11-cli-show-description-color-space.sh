#!/usr/bin/env bash
# @testcase: usage-exif-r11-cli-show-description-color-space
# @title: exif --show-description --ifd=EXIF --tag=ColorSpace prints the spec text
# @description: Requests the human-readable description for the ColorSpace tag in the EXIF IFD and verifies the output begins with "Tag 'Color Space' (0xa001, 'ColorSpace'):" and references the sRGB / Uncalibrated specification, asserting libexif ships the descriptive metadata for this tag.
# @timeout: 60
# @tags: usage, show-description, color-space
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-description --tag=ColorSpace --ifd=EXIF "$img" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" "Tag 'Color Space' (0xa001, 'ColorSpace'):"
validator_assert_contains "$tmpdir/out" "sRGB"
validator_assert_contains "$tmpdir/out" "Uncalibrated"
