#!/usr/bin/env bash
# @testcase: usage-exif-r15-cli-no-fixup-tag-color-space-srgb
# @title: exif --no-fixup --tag=ColorSpace returns "Value: sRGB" with Format Short
# @description: Reads the ColorSpace tag (in the EXIF sub-IFD) with libexif's tag-normalisation pass disabled (--no-fixup) and verifies the dump contains "Tag: 0xa001" and a "Value: sRGB" line with Format header "Format: 3 ('Short')", asserting the no-fixup code path preserves the on-disk ColorSpace SHORT unchanged.
# @timeout: 60
# @tags: usage, no-fixup, color-space
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --no-fixup --tag=ColorSpace --ifd=EXIF "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "Tag: 0xa001"
validator_assert_contains "$tmpdir/out" "Format: 3 ('Short')"
validator_assert_contains "$tmpdir/out" "Value: sRGB"
