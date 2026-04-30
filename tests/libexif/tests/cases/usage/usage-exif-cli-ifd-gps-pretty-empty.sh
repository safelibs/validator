#!/usr/bin/env bash
# @testcase: usage-exif-cli-ifd-gps-pretty-empty
# @title: exif --ifd=GPS pretty readout is graceful on a GPS-less fixture
# @description: Runs the exif client with --ifd=GPS (without --machine-readable) against the canon fixture which carries no GPS metadata, and verifies the readout exits cleanly without crashing, emits no GPS-tag labels (GPSLatitude, GPSLongitude, GPSAltitude, GPSTimeStamp), and does not leak unrelated IFD 0 / EXIF IFD labels (Manufacturer, F-Number, Color Space) into the GPS-scoped output. Pins the graceful empty contract for the human-readable IFD scope when GPS data is absent.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-ifd-gps-pretty-empty"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Must exit cleanly even though the fixture has no GPS IFD entries.
exif --ifd=GPS "$img" >"$tmpdir/out" 2>"$tmpdir/err"

# No GPS tag labels should appear in the readout.
for unwanted in 'GPSLatitude' 'GPSLongitude' 'GPSAltitude' 'GPSTimeStamp' 'GPSDateStamp'; do
  if grep -Fq -- "$unwanted" "$tmpdir/out"; then
    printf 'unexpected GPS label %s in GPS-scoped readout for a GPS-less fixture\n' "$unwanted" >&2
    cat "$tmpdir/out" >&2
    exit 1
  fi
done

# No IFD 0 / EXIF IFD labels should leak into the GPS scope.
for leak in 'Manufacturer' 'F-Number' 'Color Space' 'Exif Version' 'FlashPixVersion'; do
  if grep -Fq -- "$leak" "$tmpdir/out"; then
    printf 'unexpected non-GPS label %s leaked into GPS scope\n' "$leak" >&2
    cat "$tmpdir/out" >&2
    exit 1
  fi
done

# stderr must not carry a libexif crash diagnostic. A polite "no GPS" notice
# is fine; an assertion or backtrace is not.
if grep -qiE 'segmentation fault|assertion|backtrace|abort' "$tmpdir/err"; then
  printf 'unexpected crash-style diagnostic on stderr\n' >&2
  cat "$tmpdir/err" >&2
  exit 1
fi
