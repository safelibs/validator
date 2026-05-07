#!/usr/bin/env bash
# @testcase: usage-exif-r13-cli-set-value-image-description-readback
# @title: exif --set-value writes ImageDescription into IFD 0 and reads it back verbatim
# @description: Sets the ImageDescription tag in IFD 0 to a short ASCII string with --set-value, writes a new JPEG via --output, and verifies the machine-readable readback returns exactly that string, asserting the libexif ASCII writer for the ImageDescription (0x010E) tag round-trips through the CLI.
# @timeout: 60
# @tags: usage, set-value, image-description
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --tag=ImageDescription --ifd=0 --set-value='r13 image description' \
  --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"

exif --tag=ImageDescription --machine-readable "$tmpdir/out.jpg" >"$tmpdir/value"
read -r value <"$tmpdir/value"
if [[ "$value" != "r13 image description" ]]; then
  printf 'expected ImageDescription=r13 image description, got: %s\n' "$value" >&2
  exit 1
fi
