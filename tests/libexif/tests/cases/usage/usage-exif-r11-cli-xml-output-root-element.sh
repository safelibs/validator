#!/usr/bin/env bash
# @testcase: usage-exif-r11-cli-xml-output-root-element
# @title: exif --xml-output emits a single <exif> root element with proper close
# @description: Runs exif --xml-output without a tag selector and verifies the document opens with <exif> on line 1, closes with </exif> on the last line, and produces exactly one closing tag, asserting the well-formed wrapper around the per-tag XML elements.
# @timeout: 60
# @tags: usage, xml-output, structure
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/out"

read -r first <"$tmpdir/out"
if [[ "$first" != "<exif>" ]]; then
  printf 'expected first line <exif>, got: %s\n' "$first" >&2
  exit 1
fi

last=$(tail -n 1 "$tmpdir/out")
if [[ "$last" != "</exif>" ]]; then
  printf 'expected last line </exif>, got: %s\n' "$last" >&2
  exit 1
fi

count=$(grep -c '</exif>' "$tmpdir/out")
if (( count != 1 )); then
  printf 'expected exactly 1 </exif> closing tag, got %d\n' "$count" >&2
  exit 1
fi
