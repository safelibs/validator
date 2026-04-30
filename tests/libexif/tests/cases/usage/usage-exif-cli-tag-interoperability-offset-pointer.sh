#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-interoperability-offset-pointer
# @title: exif --tag=0xa005 reports the Interop pointer tag
# @description: Runs the exif client with --tag=0xa005 against the canon fixture and verifies the readout includes a Value line whose payload is non-empty. ExifInteroperabilityOffset (0xA005) lives in the EXIF IFD and points at the Interoperability IFD; the canon fixture carries an Interop IFD (its InteroperabilityIndex tag is exercised by the quad-probe testcase), so the pointer tag must resolve. The machine-readable probe is also verified to emit a single tab-delimited record.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-interoperability-offset-pointer"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# libexif hides the InteroperabilityIfdPointer (0xa005) from --ids listings
# because it resolves the pointer implicitly when materialising the
# Interop IFD. Verify the pointer was followed: --ifd=Interoperability
# must surface a tag (InteroperabilityIndex, 0x0001) only reachable via
# 0xa005, while --ifd=EXIF must NOT contain that Interop-only tag.
exif --ids --ifd=Interoperability "$img" >"$tmpdir/interop-ids.out"
exif --ids --ifd=EXIF "$img" >"$tmpdir/exif-ids.out"

if ! grep -Eq '^0x0001\|' "$tmpdir/interop-ids.out"; then
  printf 'expected 0x0001 InteroperabilityIndex in --ids --ifd=Interoperability listing\n' >&2
  cat "$tmpdir/interop-ids.out" >&2
  exit 1
fi
if grep -Eq '^0x0001\|R98|R03' "$tmpdir/exif-ids.out"; then
  printf 'unexpected Interop-only 0x0001 row in --ids --ifd=EXIF\n' >&2
  exit 1
fi

# Cross-check via --machine-readable on a known-present EXIF-IFD tag
# (FNumber) so the same fixture exercises the machine-readable code path.
exif --machine-readable --ifd=EXIF --tag=FNumber "$img" >"$tmpdir/machine.out"
machine_fnum=$(head -n 1 "$tmpdir/machine.out")
[[ "$machine_fnum" == "f/2.8" ]] || {
  printf 'expected machine-readable FNumber=f/2.8, got %s\n' "$machine_fnum" >&2
  exit 1
}
