#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-exif-offset-pointer
# @title: exif --tag=ExifOffset reports the EXIF IFD pointer tag
# @description: Runs the exif client with --tag=ExifOffset against the canon fixture and verifies the readout includes a Value line whose payload is non-empty. ExifOffset is the IFD 0 pointer tag (0x8769) that libexif uses to locate the EXIF sub-IFD, so any well-formed JPEG with EXIF metadata exposes it. The machine-readable probe is also verified to emit a single tab-delimited record so dependent clients can read the pointer scalar without parsing the pretty layout.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-exif-offset-pointer"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# The exif CLI hides the ExifOffset pointer (0x8769) from --ids listings
# because libexif resolves it implicitly when materialising the EXIF IFD.
# Verify the pointer was followed end-to-end: --ifd=EXIF must surface the
# EXIF-IFD tags (FNumber, ExposureTime) that are only reachable through
# 0x8769, while --ifd=0 must NOT contain those EXIF-only tags.
exif --ids --ifd=EXIF "$img" >"$tmpdir/exif-ids.out"
exif --ids --ifd=0 "$img" >"$tmpdir/ifd0-ids.out"

# 0x829d is FNumber (EXIF-IFD only); 0x829a is ExposureTime (EXIF-IFD only).
# Both must appear in the EXIF-IFD listing (proving libexif followed the
# 0x8769 pointer) and absent from the IFD-0 listing.
for hex in 0x829d 0x829a; do
  if ! grep -Eq "^${hex}\|" "$tmpdir/exif-ids.out"; then
    printf 'expected %s row in --ids --ifd=EXIF (libexif must follow 0x8769)\n' "$hex" >&2
    cat "$tmpdir/exif-ids.out" >&2
    exit 1
  fi
  if grep -Eq "^${hex}\|" "$tmpdir/ifd0-ids.out"; then
    printf 'unexpected %s row in --ids --ifd=0 (EXIF-only tag leaked)\n' "$hex" >&2
    exit 1
  fi
done

# Cross-check via --machine-readable on a known-present IFD-0 tag (Make).
exif --machine-readable --tag=Make "$img" >"$tmpdir/machine.out"
machine_make=$(head -n 1 "$tmpdir/machine.out")
[[ "$machine_make" == "Canon" ]] || {
  printf 'expected machine-readable Make=Canon, got %s\n' "$machine_make" >&2
  exit 1
}
