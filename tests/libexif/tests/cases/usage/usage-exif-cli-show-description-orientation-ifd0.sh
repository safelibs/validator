#!/usr/bin/env bash
# @testcase: usage-exif-cli-show-description-orientation-ifd0
# @title: exif --show-description Orientation in IFD 0
# @description: Invokes exif --show-description --ifd=0 --tag=Orientation against the canon fixture and verifies the human readable description references the canonical hex tag id 0x0112, the symbolic Orientation name, and the substring image orientation viewed in terms of rows and columns shipped by libexif.
# @timeout: 60
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-show-description-orientation-ifd0"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-description --ifd=0 --tag=Orientation "$img" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" "Tag 'Orientation'"
validator_assert_contains "$tmpdir/out" '0x0112'
validator_assert_contains "$tmpdir/out" "'Orientation'"
validator_assert_contains "$tmpdir/out" 'image orientation viewed in terms of rows and columns'
