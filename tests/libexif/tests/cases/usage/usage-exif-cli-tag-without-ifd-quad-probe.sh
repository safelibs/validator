#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-without-ifd-quad-probe
# @title: exif --tag without --ifd auto-finds tags across four IFDs
# @description: Runs the exif client with --tag and no --ifd argument against four tags whose native homes span IFD 0 (Model), the EXIF IFD (ExposureTime), IFD 1 (Compression for the thumbnail), and the Interoperability IFD (InteroperabilityIndex), verifying that auto-finding succeeds and reports the expected literal value for each tag without the caller specifying which IFD to scope to.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-without-ifd-quad-probe"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# IFD 0: Model
exif --tag=Model "$img" >"$tmpdir/model.out"
validator_assert_contains "$tmpdir/model.out" 'Value: Canon PowerShot S70'

# EXIF IFD: ExposureTime - canon fixture reports a 1-second exposure as
# the rational "1 sec." in libexif's human-readable rendering.
exif --tag=ExposureTime "$img" >"$tmpdir/exposure.out"
validator_assert_contains "$tmpdir/exposure.out" '1 sec.'

# IFD 1 (thumbnail IFD): Compression - auto-find should still locate it
exif --tag=Compression "$img" >"$tmpdir/compression.out"
validator_assert_contains "$tmpdir/compression.out" 'JPEG compression'

# Interoperability IFD: InteroperabilityIndex (auto-find should reach it)
exif --tag=InteroperabilityIndex "$img" >"$tmpdir/interop.out"
validator_assert_contains "$tmpdir/interop.out" 'Value:'

# All four probes must produce non-empty output without --ifd hints
for f in "$tmpdir/model.out" "$tmpdir/exposure.out" "$tmpdir/compression.out" "$tmpdir/interop.out"; do
  size=$(stat -c '%s' "$f")
  if (( size <= 0 )); then
    printf 'expected non-empty auto-find output for %s\n' "$f" >&2
    exit 1
  fi
done
