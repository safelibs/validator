#!/usr/bin/env bash
# @testcase: usage-exif-r14-cli-ifd-exif-machine-readable-exposure-time
# @title: exif --ifd=EXIF combined with --machine-readable --tag=ExposureTime emits "1 sec."
# @description: Combines --ifd=EXIF (scoping the lookup to the EXIF sub-IFD where ExposureTime lives) with --machine-readable --tag=ExposureTime and verifies the output is exactly "1 sec." with a single trailing newline, asserting libexif honours the IFD scope alongside the machine-readable codepath without altering the formatted value.
# @timeout: 60
# @tags: usage, machine-readable, ifd-exif, exposure-time
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=EXIF --machine-readable --tag=ExposureTime "$img" >"$tmpdir/out"
read -r value <"$tmpdir/out"
if [[ "$value" != "1 sec." ]]; then
  printf 'expected ExposureTime=1 sec., got: %s\n' "$value" >&2
  exit 1
fi

lines=$(wc -l <"$tmpdir/out")
if (( lines != 1 )); then
  printf 'expected exactly 1 line, got %d\n' "$lines" >&2
  exit 1
fi
