#!/usr/bin/env bash
# @testcase: usage-exif-r14-cli-no-fixup-tag-make-canon
# @title: exif --no-fixup --tag=Make returns "Value: Canon" without applying tag normalisation
# @description: Reads the Make tag with libexif's tag-normalisation pass disabled (--no-fixup) and verifies the dump's Value line is "Value: Canon" exactly, asserting the no-fixup code path preserves the on-disk Make ASCII unchanged for a tag that needs no fixup.
# @timeout: 60
# @tags: usage, no-fixup, make
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --no-fixup --tag=Make --ifd=0 "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "Value: Canon"
validator_assert_contains "$tmpdir/out" "Tag: 0x10f"
