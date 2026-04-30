#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-resolution-unit-paired-resolutions
# @title: exif --tag=ResolutionUnit consistent with XResolution and YResolution
# @description: Reads ResolutionUnit, XResolution, and YResolution from the canon fixture with the exif client, verifies the unit is reported as Inch and that XResolution and YResolution both surface their numeric ratios so callers parsing DPI metadata see all three tags consistently from one tool invocation per tag.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-resolution-unit-paired-resolutions"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=ResolutionUnit "$img" >"$tmpdir/unit.out"
validator_assert_contains "$tmpdir/unit.out" 'Inch'
validator_assert_contains "$tmpdir/unit.out" 'Value:'

exif --tag=XResolution "$img" >"$tmpdir/xres.out"
validator_assert_contains "$tmpdir/xres.out" 'Value:'

exif --tag=YResolution "$img" >"$tmpdir/yres.out"
validator_assert_contains "$tmpdir/yres.out" 'Value:'

# All three reads must succeed and produce non-empty stdout
for f in "$tmpdir/unit.out" "$tmpdir/xres.out" "$tmpdir/yres.out"; do
  size=$(stat -c '%s' "$f")
  if (( size <= 0 )); then
    printf 'expected non-empty output for %s\n' "$f" >&2
    exit 1
  fi
done

# The X and Y resolution outputs are independent records, but they must both be
# anchored to the same "Resolution" wording, since the canon fixture uses inch
# units for both axes.
validator_assert_contains "$tmpdir/xres.out" 'Resolution'
validator_assert_contains "$tmpdir/yres.out" 'Resolution'
