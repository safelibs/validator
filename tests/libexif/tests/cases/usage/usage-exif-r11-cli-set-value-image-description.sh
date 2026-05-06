#!/usr/bin/env bash
# @testcase: usage-exif-r11-cli-set-value-image-description
# @title: exif --set-value writes ImageDescription into IFD 0 and reads it back
# @description: Sets the ImageDescription tag in IFD 0 to a short ASCII string, writes the JPEG to a new path, and verifies the machine-readable readback returns the same string verbatim, exercising another text-tag writer in IFD 0 distinct from Make/Artist/Copyright already covered.
# @timeout: 60
# @tags: usage, metadata, set-value, image-description
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --tag=ImageDescription --ifd=0 --set-value='hello world' --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >/dev/null

exif --tag=ImageDescription --machine-readable "$tmpdir/out.jpg" >"$tmpdir/value"
read -r value <"$tmpdir/value"
if [[ "$value" != "hello world" ]]; then
  printf 'expected ImageDescription=hello world, got: %s\n' "$value" >&2
  exit 1
fi
