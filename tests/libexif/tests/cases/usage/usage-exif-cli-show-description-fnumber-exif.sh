#!/usr/bin/env bash
# @testcase: usage-exif-cli-show-description-fnumber-exif
# @title: exif --show-description FNumber in IFD EXIF
# @description: Invokes exif --show-description --ifd=EXIF --tag=FNumber on the canon fixture and verifies libexif resolves the EXIF subdirectory binding so the description names the F-Number tag with hex id 0x829d and the canonical short description The F number, distinguishing the tag from a same-named entry in IFD 0.
# @timeout: 60
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-show-description-fnumber-exif"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-description --ifd=EXIF --tag=FNumber "$img" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" "Tag 'F-Number'"
validator_assert_contains "$tmpdir/out" '0x829d'
validator_assert_contains "$tmpdir/out" "'FNumber'"
validator_assert_contains "$tmpdir/out" 'The F number.'
