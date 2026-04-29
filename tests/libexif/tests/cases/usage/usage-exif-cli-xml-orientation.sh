#!/usr/bin/env bash
# @testcase: usage-exif-cli-xml-orientation
# @title: exif XML orientation tag
# @description: Emits XML metadata and verifies the orientation element in the serialized output.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-xml-orientation"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '<Orientation>Right-top</Orientation>'
