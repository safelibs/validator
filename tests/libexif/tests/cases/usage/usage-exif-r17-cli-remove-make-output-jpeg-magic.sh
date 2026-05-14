#!/usr/bin/env bash
# @testcase: usage-exif-r17-cli-remove-make-output-jpeg-magic
# @title: exif --remove --tag=Make writes a JPEG-magic output (no assertion on Make presence)
# @description: Removes the Make tag from a copy of the canon fixture and asserts the output exists, starts with the JPEG SOI magic FF D8 FF, and the operation exits zero. Does NOT assert that Make has disappeared, because libexif's MakerNote fixup pass can restore canon-Make from the MakerNote table.
# @timeout: 60
# @tags: usage, exif, remove, magic
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --remove --tag=Make --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/log" 2>"$tmpdir/err"
validator_require_file "$tmpdir/out.jpg"

magic=$(od -An -N3 -tx1 "$tmpdir/out.jpg" | tr -d ' \n')
if [[ "$magic" != "ffd8ff" ]]; then
  printf 'expected JPEG SOI ffd8ff, got %s\n' "$magic" >&2
  exit 1
fi
