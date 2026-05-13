#!/usr/bin/env bash
# @testcase: usage-exif-r16-cli-show-mnote-canon-variant-tag-count
# @title: exif --show-mnote on canon fixture emits multiple Tag: lines
# @description: Runs exif --show-mnote against the canon makernote fixture and asserts the maker-note dump contains at least two "Tag: 0x" lines, exercising libexif's Canon maker-note parser through the CLI without depending on any specific tag value.
# @timeout: 60
# @tags: usage, mnote, canon
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-mnote "$img" >"$tmpdir/mnote.out"

count=$(LC_ALL=C grep -c '^Tag: 0x' "$tmpdir/mnote.out" || true)
if (( count < 2 )); then
  printf 'expected at least 2 Tag: 0x lines, got %d\n' "$count" >&2
  sed -n '1,40p' "$tmpdir/mnote.out" >&2
  exit 1
fi
