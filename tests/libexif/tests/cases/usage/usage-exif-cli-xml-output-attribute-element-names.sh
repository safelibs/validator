#!/usr/bin/env bash
# @testcase: usage-exif-cli-xml-output-attribute-element-names
# @title: exif --xml-output emits well-formed element names with matching close tags
# @description: Runs the exif client with --xml-output against the canon fixture and asserts the stream surfaces the expected element names (Color_Space, Flash, Pixel_X_Dimension, File_Source) with both opening and closing tags, that every opening tag in the output has a matching closing tag count, and that there is at least one element so the XML output is structurally non-empty.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-xml-output-attribute-element-names"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/xml.out"
size=$(stat -c '%s' "$tmpdir/xml.out")
if (( size <= 0 )); then
  printf 'expected non-empty --xml-output stream\n' >&2
  exit 1
fi

# Each of these elements must appear with matching open and close tags.
# libexif's --xml-output uses underscore-separated tag titles (e.g.
# "Color Space" becomes <Color_Space>).
for elem in Color_Space Flash Pixel_X_Dimension File_Source; do
  if ! grep -Fq "<${elem}>" "$tmpdir/xml.out"; then
    printf 'expected opening <%s> in --xml-output\n' "$elem" >&2
    cat "$tmpdir/xml.out" >&2
    exit 1
  fi
  if ! grep -Fq "</${elem}>" "$tmpdir/xml.out"; then
    printf 'expected closing </%s> in --xml-output\n' "$elem" >&2
    cat "$tmpdir/xml.out" >&2
    exit 1
  fi
done

# Every distinct opening element name must have at least as many closes as opens.
opens=$(grep -oE '<[A-Za-z][A-Za-z0-9_]*>' "$tmpdir/xml.out" | wc -l)
closes=$(grep -oE '</[A-Za-z][A-Za-z0-9_]*>' "$tmpdir/xml.out" | wc -l)
if (( opens == 0 )); then
  printf 'expected at least one element open tag in --xml-output\n' >&2
  exit 1
fi
if (( opens != closes )); then
  printf 'unbalanced --xml-output: opens=%d closes=%d\n' "$opens" "$closes" >&2
  cat "$tmpdir/xml.out" >&2
  exit 1
fi
