#!/usr/bin/env bash
# @testcase: usage-exif-r15-cli-no-fixup-tag-model-canon-powershot
# @title: exif --no-fixup --tag=Model returns "Value: Canon PowerShot S70"
# @description: Reads the Model tag with libexif's tag-normalisation pass disabled (--no-fixup) and verifies the dump's Value line is "Value: Canon PowerShot S70" exactly and the Tag header is "Tag: 0x110", asserting the no-fixup code path preserves the on-disk Model ASCII unchanged for a tag that needs no fixup.
# @timeout: 60
# @tags: usage, no-fixup, model
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --no-fixup --tag=Model --ifd=0 "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "Value: Canon PowerShot S70"
validator_assert_contains "$tmpdir/out" "Tag: 0x110"
