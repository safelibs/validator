#!/usr/bin/env bash
# @testcase: usage-exif-r19-cli-xml-output-root-element
# @title: exif -x output opens with an exif root element tag
# @description: Runs exif -x on the canon fixture and asserts the first non-empty line of stdout contains an opening "<exif" element tag (libexif's XML output starts with a single root element), exercising the libexif XML serialiser through the exif CLI.
# @timeout: 60
# @tags: usage, exif, xml, root-element, r19
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif -x "$img" >"$tmpdir/out" 2>"$tmpdir/err"

first=$(LC_ALL=C grep -m1 -v '^[[:space:]]*$' "$tmpdir/out" || true)
case "$first" in
  *'<exif'*) ;;
  *)
    printf 'expected first non-empty line to contain <exif, got: %s\n' "$first" >&2
    head -c 4096 "$tmpdir/out" >&2
    exit 1
    ;;
esac
