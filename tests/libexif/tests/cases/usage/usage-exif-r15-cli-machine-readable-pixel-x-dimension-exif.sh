#!/usr/bin/env bash
# @testcase: usage-exif-r15-cli-machine-readable-pixel-x-dimension-exif
# @title: exif --ifd=EXIF --machine-readable --tag=PixelXDimension emits exactly "640"
# @description: Reads the PixelXDimension tag from the EXIF sub-IFD in --machine-readable mode and verifies the output is exactly the literal string "640" plus a single newline with line count == 1, asserting libexif emits the bare SHORT/LONG value of the imaged-region width without surrounding annotation in machine-readable mode.
# @timeout: 60
# @tags: usage, machine-readable, pixel-x-dimension, ifd-exif
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=EXIF --machine-readable --tag=PixelXDimension "$img" >"$tmpdir/out"
read -r value <"$tmpdir/out"
if [[ "$value" != "640" ]]; then
  printf 'expected PixelXDimension=640, got: %s\n' "$value" >&2
  exit 1
fi

lines=$(wc -l <"$tmpdir/out")
if (( lines != 1 )); then
  printf 'expected exactly 1 line, got %d\n' "$lines" >&2
  exit 1
fi
