#!/usr/bin/env bash
# @testcase: usage-exif-r10-cli-machine-focal-plane-resolution-unit
# @title: exif machine FocalPlaneResolutionUnit emits the unit string
# @description: Reads the focal-plane resolution unit tag in machine-readable form against the canon fixture and verifies the scoped output is a single line equal to "Inch" libexif derives from the stored Short value, so callers can pair the FocalPlaneX/Y machine values with their declared unit.
# @timeout: 60
# @tags: usage, metadata, focal-plane
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=FocalPlaneResolutionUnit "$img" >"$tmpdir/out"

line_count=$(wc -l <"$tmpdir/out")
if (( line_count != 1 )); then
  printf 'expected exactly 1 line, got %d\n' "$line_count" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi

read -r value <"$tmpdir/out"
if [[ "$value" != "Inch" ]]; then
  printf 'expected Inch, got: %s\n' "$value" >&2
  exit 1
fi
