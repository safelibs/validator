#!/usr/bin/env bash
# @testcase: usage-exif-r11-cli-set-value-artist-roundtrip
# @title: exif --set-value writes Artist into IFD 0 and reads it back
# @description: Sets the Artist tag in IFD 0 to a multi-word ASCII string, writes the JPEG to a new path, and verifies the machine-readable readback returns the same string verbatim with no surrounding annotation, exercising the ASCII writer for a tag not present in the source fixture.
# @timeout: 60
# @tags: usage, metadata, set-value, artist
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --tag=Artist --ifd=0 --set-value='Cap Hopper' --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"

exif --tag=Artist --machine-readable "$tmpdir/out.jpg" >"$tmpdir/value"
read -r value <"$tmpdir/value"
if [[ "$value" != "Cap Hopper" ]]; then
  printf 'expected Artist=Cap Hopper, got: %s\n' "$value" >&2
  exit 1
fi
