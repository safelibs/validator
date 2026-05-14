#!/usr/bin/env bash
# @testcase: usage-exif-r17-cli-tag-by-hex-pixel-x-dim-readback
# @title: exif -t 0xa002 (PixelXDimension) machine readback equals 640
# @description: Reads the PixelXDimension EXIF-IFD tag by its hex tag id 0xa002 via exif -t 0xa002 --machine-readable and asserts the captured single-line value equals "640" exactly, exercising libexif's tag-id lookup path through the short -t alias.
# @timeout: 60
# @tags: usage, exif, hex-tag-id, pixel-x-dim
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable -t 0xa002 "$img" >"$tmpdir/out"
read -r value <"$tmpdir/out"
if [[ "$value" != "640" ]]; then
  printf 'expected 640, got %s\n' "$value" >&2
  exit 1
fi
