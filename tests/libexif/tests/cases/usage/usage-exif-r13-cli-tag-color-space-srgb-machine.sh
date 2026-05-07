#!/usr/bin/env bash
# @testcase: usage-exif-r13-cli-tag-color-space-srgb-machine
# @title: exif --machine-readable --tag=ColorSpace returns "sRGB" exactly
# @description: Reads the ColorSpace tag from the canon fixture in --machine-readable mode and verifies the output is exactly the literal string "sRGB" plus a single newline, asserting libexif decodes the standard ColorSpace value 1 to its conventional label without surrounding annotation.
# @timeout: 60
# @tags: usage, machine-readable, color-space
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=ColorSpace "$img" >"$tmpdir/out"
read -r value <"$tmpdir/out"
if [[ "$value" != "sRGB" ]]; then
  printf 'expected ColorSpace=sRGB, got: %s\n' "$value" >&2
  exit 1
fi
