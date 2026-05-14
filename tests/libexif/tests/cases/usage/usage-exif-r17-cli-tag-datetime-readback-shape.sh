#!/usr/bin/env bash
# @testcase: usage-exif-r17-cli-tag-datetime-readback-shape
# @title: exif --tag=DateTime machine readback shape YYYY:MM:DD HH:MM:SS
# @description: Reads the DateTime tag from the canon fixture via exif --machine-readable --tag=DateTime and asserts the single-line output matches the EXIF date-time shape YYYY:MM:DD HH:MM:SS (extended ASCII regex), exercising libexif's ASCII tag readback for IFD0 DateTime.
# @timeout: 60
# @tags: usage, exif, datetime, shape
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=DateTime "$img" >"$tmpdir/out"
read -r value <"$tmpdir/out"
if ! LC_ALL=C printf '%s' "$value" | grep -Eq '^[0-9]{4}:[0-9]{2}:[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'; then
  printf 'DateTime did not match YYYY:MM:DD HH:MM:SS, got: %s\n' "$value" >&2
  exit 1
fi
