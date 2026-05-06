#!/usr/bin/env bash
# @testcase: usage-exif-r9-cli-no-fixup-tag-orientation
# @title: exif --no-fixup with Orientation tag
# @description: Runs exif --no-fixup --tag=Orientation on the fixture and confirms the tag value is still rendered without any fixup intervention.
# @timeout: 60
# @tags: usage, metadata, no-fixup
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --no-fixup --tag=Orientation "$img" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'Value:'
validator_assert_contains "$tmpdir/out" 'Orientation'
