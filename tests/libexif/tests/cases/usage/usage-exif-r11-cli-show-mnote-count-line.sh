#!/usr/bin/env bash
# @testcase: usage-exif-r11-cli-show-mnote-count-line
# @title: exif --show-mnote opens with the MakerNote value-count line
# @description: Runs exif --show-mnote against the canon fixture and verifies the first line is exactly "MakerNote contains 96 values:", confirming libexif decodes the Canon MakerNote and reports the entry count up front.
# @timeout: 60
# @tags: usage, mnote, count
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-mnote "$img" >"$tmpdir/out"

read -r first <"$tmpdir/out"
if [[ "$first" != "MakerNote contains 96 values:" ]]; then
  printf 'expected MakerNote count line, got: %s\n' "$first" >&2
  exit 1
fi
