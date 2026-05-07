#!/usr/bin/env bash
# @testcase: usage-exif-r12-cli-extract-thumbnail-default-output-path
# @title: exif -e short flag extracts the embedded thumbnail with a JPEG SOI/EOI envelope
# @description: Runs exif with the short -e flag (alias for --extract-thumbnail) and --output to a fresh path, and verifies the produced file starts with the JPEG SOI 0xFFD8 magic and ends with the EOI 0xFFD9 marker, asserting libexif emits a complete JPEG envelope rather than truncated payload bytes.
# @timeout: 60
# @tags: usage, extract-thumbnail, short-flag
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif -e --output="$tmpdir/thumb.jpg" "$img" >"$tmpdir/log"
validator_assert_contains "$tmpdir/log" "Wrote file"
[[ -s "$tmpdir/thumb.jpg" ]] || { echo "thumbnail not created" >&2; exit 1; }

soi=$(head -c 2 "$tmpdir/thumb.jpg" | od -An -tx1 | tr -d ' \n')
if [[ "$soi" != "ffd8" ]]; then
  printf 'expected JPEG SOI ffd8, got: %s\n' "$soi" >&2
  exit 1
fi

eoi=$(tail -c 2 "$tmpdir/thumb.jpg" | od -An -tx1 | tr -d ' \n')
if [[ "$eoi" != "ffd9" ]]; then
  printf 'expected JPEG EOI ffd9, got: %s\n' "$eoi" >&2
  exit 1
fi
