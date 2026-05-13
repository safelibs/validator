#!/usr/bin/env bash
# @testcase: usage-exif-r16-cli-machine-orientation-top-left
# @title: exif --machine-readable --tag Orientation returns Top-left for canon fixture
# @description: Reads the Orientation tag of the canon fixture in machine-readable mode and asserts the single-line value is exactly "Top-left", exercising libexif's SHORT-to-text rendering for the Orientation (0x0112) tag.
# @timeout: 60
# @tags: usage, machine-readable, orientation
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=Orientation "$img" >"$tmpdir/val"
read -r value <"$tmpdir/val"
if [[ "$value" != "Top-left" ]]; then
  printf 'expected Orientation=Top-left, got: %s\n' "$value" >&2
  exit 1
fi

lines=$(wc -l <"$tmpdir/val")
if (( lines != 1 )); then
  printf 'expected exactly 1 line, got %d\n' "$lines" >&2
  exit 1
fi
