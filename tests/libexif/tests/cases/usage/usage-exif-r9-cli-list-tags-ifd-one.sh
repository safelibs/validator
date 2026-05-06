#!/usr/bin/env bash
# @testcase: usage-exif-r9-cli-list-tags-ifd-one
# @title: exif --list-tags includes IFD 1 thumbnail tags
# @description: Lists EXIF tag definitions on the fixture and verifies entries that belong to IFD 1 (thumbnail) such as Compression are present.
# @timeout: 60
# @tags: usage, metadata, ifd
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --list-tags --ifd=1 "$img" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'Compression'
