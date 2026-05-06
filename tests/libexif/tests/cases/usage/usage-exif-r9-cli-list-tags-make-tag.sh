#!/usr/bin/env bash
# @testcase: usage-exif-r9-cli-list-tags-make-tag
# @title: exif --list-tags includes Make tag
# @description: Lists EXIF tag definitions in the fixture image with --list-tags and confirms the canonical Make tag entry is present in the output.
# @timeout: 60
# @tags: usage, metadata, tags
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --list-tags "$img" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'Make'
