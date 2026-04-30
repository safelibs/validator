#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-ifd-zero-tabs
# @title: exif --machine-readable --ifd=0 emits IFD 0 tags
# @description: Runs the exif client with --machine-readable --ifd=0 and verifies the IFD 0 tab-delimited stream contains the Manufacturer and Model entries while excluding EXIF-IFD-only tags such as F-Number.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-ifd-zero-tabs"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --ifd=0 "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" $'Manufacturer\tCanon'
validator_assert_contains "$tmpdir/out" $'Model\tCanon PowerShot S70'
validator_assert_contains "$tmpdir/out" $'Orientation\tRight-top'

# F-Number lives in the EXIF IFD, not IFD 0
if grep -q '^F-Number' "$tmpdir/out"; then
  printf 'unexpected F-Number entry in IFD 0 stream\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
