#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-flashpix-version-show-description
# @title: exif --show-description --tag=FlashPixVersion prints help text
# @description: Asks the exif client for the FlashPixVersion tag description with --show-description --ifd=EXIF and verifies the standard EXIF documentation string is reported including the symbolic name and the explanatory text about the supported FlashPix format version.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-flashpix-version-show-description"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-description --tag=FlashPixVersion --ifd=EXIF "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "FlashPixVersion"
# Description text references the FlashPix format and version-record nature
if ! grep -Eqi 'FlashPix|Flashpix' "$tmpdir/out"; then
  printf 'expected FlashPix mention in --show-description output\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
if ! grep -Eqi 'version|supported' "$tmpdir/out"; then
  printf 'expected description to mention version/supported semantics\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
