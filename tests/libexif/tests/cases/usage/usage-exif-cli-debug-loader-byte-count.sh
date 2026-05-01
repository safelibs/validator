#!/usr/bin/env bash
# @testcase: usage-exif-cli-debug-loader-byte-count
# @title: exif --debug emits the ExifLoader byte-count trace
# @description: Runs exif with --debug against the canon fixture and verifies the loader-side trace lines appear, including the "ExifLoader: Scanning" line with a positive byte count, the "ExifData: Parsing" line with its own byte count, the "Found EXIF header at start." marker, and the per-IFD entry count line for IFD 0. Pins libexif's verbose debug surface on Ubuntu 24.04 for callers that capture loader telemetry.
# @timeout: 120
# @tags: usage, metadata, debug
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-debug-loader-byte-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --debug --tag=Orientation --ifd=0 "$img" >"$tmpdir/out" 2>"$tmpdir/err"
cat "$tmpdir/out" "$tmpdir/err" >"$tmpdir/all"

# Loader trace
validator_assert_contains "$tmpdir/all" 'ExifLoader: Scanning'
validator_assert_contains "$tmpdir/all" 'byte(s) of data'

# Parser trace and EXIF marker
validator_assert_contains "$tmpdir/all" 'ExifData: Parsing'
validator_assert_contains "$tmpdir/all" 'Found EXIF header at start.'

# IFD 0 entry-count trace
validator_assert_contains "$tmpdir/all" 'IFD 0 at 8.'
validator_assert_contains "$tmpdir/all" 'Loading 9 entries'

# The actual entry readout must still be present at the tail of the run
validator_assert_contains "$tmpdir/all" "Tag: 0x112 ('Orientation')"
validator_assert_contains "$tmpdir/all" 'Value: Right-top'

# The Scanning line must report a positive byte count.
scan_line=$(grep -m1 'ExifLoader: Scanning' "$tmpdir/all")
if ! [[ "$scan_line" =~ Scanning\ ([0-9]+)\ byte ]]; then
  printf 'could not parse Scanning byte count from: %s\n' "$scan_line" >&2
  exit 1
fi
scan_bytes=${BASH_REMATCH[1]}
if (( scan_bytes <= 0 )); then
  printf 'expected positive scan byte count, got %d\n' "$scan_bytes" >&2
  exit 1
fi
