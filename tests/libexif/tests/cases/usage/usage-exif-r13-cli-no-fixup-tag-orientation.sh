#!/usr/bin/env bash
# @testcase: usage-exif-r13-cli-no-fixup-tag-orientation
# @title: exif --no-fixup --tag=Orientation still surfaces the canon fixture's Orientation entry
# @description: Reads the Orientation tag with libexif's tag-normalisation pass disabled (--no-fixup) and verifies the dump still labels the entry as the canonical "Orientation" with Format "Short", asserting the no-fixup code path preserves a tag that needs no fixup.
# @timeout: 60
# @tags: usage, no-fixup, orientation
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --no-fixup --tag=Orientation --ifd=0 "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "Tag: 0x112"
validator_assert_contains "$tmpdir/out" "Format: 3 ('Short')"
