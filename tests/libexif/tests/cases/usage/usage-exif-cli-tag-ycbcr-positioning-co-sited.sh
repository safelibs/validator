#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-ycbcr-positioning-co-sited
# @title: exif --tag=YCbCrPositioning reports the textual position keyword
# @description: Reads YCbCrPositioning with the exif client against the canon fixture and verifies the human-readable text mode reports a recognized chroma positioning keyword (either Co-sited or Centered, both spec-defined) and that the same tag in --machine-readable mode also emits that keyword on its bare line.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-ycbcr-positioning-co-sited"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=YCbCrPositioning "$img" >"$tmpdir/text.out"
exif --machine-readable --tag=YCbCrPositioning "$img" >"$tmpdir/machine.out"

# Spec defines the field as 1=Centered, 2=Co-sited; the JPEG fixture must hit
# one of those literals in text mode.
if ! grep -Eq 'Co-sited|Centered' "$tmpdir/text.out"; then
  printf 'expected Co-sited or Centered in YCbCrPositioning text output\n' >&2
  cat "$tmpdir/text.out" >&2
  exit 1
fi

# The same keyword must also appear in machine-readable output, regardless of
# which of the two values the fixture carries.
if ! grep -Eq 'Co-sited|Centered' "$tmpdir/machine.out"; then
  printf 'expected Co-sited or Centered in YCbCrPositioning machine-readable output\n' >&2
  cat "$tmpdir/machine.out" >&2
  exit 1
fi

# Whichever keyword the text mode reports must match the machine-readable mode.
text_keyword=$(grep -oE 'Co-sited|Centered' "$tmpdir/text.out" | head -n 1)
machine_keyword=$(grep -oE 'Co-sited|Centered' "$tmpdir/machine.out" | head -n 1)
if [[ "$text_keyword" != "$machine_keyword" ]]; then
  printf 'YCbCrPositioning keyword mismatch: text=%q machine=%q\n' \
    "$text_keyword" "$machine_keyword" >&2
  exit 1
fi
