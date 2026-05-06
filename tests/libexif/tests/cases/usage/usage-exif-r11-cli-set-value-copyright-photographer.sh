#!/usr/bin/env bash
# @testcase: usage-exif-r11-cli-set-value-copyright-photographer
# @title: exif --set-value Copyright records photographer with editor placeholder
# @description: Writes the Copyright tag with a photographer-only string and verifies the machine-readable readback reports the photographer text and the libexif "(Photographer) - [None] (Editor)" template, exercising the dual-string Copyright structure.
# @timeout: 60
# @tags: usage, metadata, set-value, copyright
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --tag=Copyright --ifd=0 --set-value='2026 Test (C)' --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >/dev/null

exif --tag=Copyright --machine-readable "$tmpdir/out.jpg" >"$tmpdir/value"
read -r value <"$tmpdir/value"
expected='2026 Test (C) (Photographer) - [None] (Editor)'
if [[ "$value" != "$expected" ]]; then
  printf 'expected Copyright=%q, got: %q\n' "$expected" "$value" >&2
  exit 1
fi
