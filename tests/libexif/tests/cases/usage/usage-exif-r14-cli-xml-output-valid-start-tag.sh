#!/usr/bin/env bash
# @testcase: usage-exif-r14-cli-xml-output-valid-start-tag
# @title: exif --xml-output emits a valid root-element start tag at offset 0
# @description: Runs exif --xml-output against the canon fixture and verifies the very first line of output begins with "<" followed by an alphabetic character (a valid XML start tag), asserting libexif emits a textual XML stream rather than a binary blob or stray prefix bytes when --xml-output is requested.
# @timeout: 60
# @tags: usage, xml-output
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/xml.out"

read -r first_line <"$tmpdir/xml.out"
if [[ ! "$first_line" =~ ^\<[A-Za-z] ]]; then
  printf 'expected first line to begin with <[A-Za-z], got: %s\n' "$first_line" >&2
  exit 1
fi
