#!/usr/bin/env bash
# @testcase: usage-exif-r16-cli-no-fixup-remove-make-exit-zero
# @title: exif --no-fixup --remove --tag Make exits zero and writes a JPEG
# @description: Removes the Make tag with libexif's --no-fixup pass disabled (so the MakerNote fixup cannot restore Make from the canon MakerNote table), and asserts the operation exits zero, writes a JPEG-typed output, and produces a file size no larger than the input.
# @timeout: 60
# @tags: usage, no-fixup, remove
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --no-fixup --remove --tag=Make --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/log"

validator_require_file "$tmpdir/out.jpg"
file -b "$tmpdir/out.jpg" | grep -qi JPEG

in_sz=$(wc -c <"$tmpdir/in.jpg")
out_sz=$(wc -c <"$tmpdir/out.jpg")
[[ "$out_sz" -le "$in_sz" ]] || {
  printf 'expected out (%s) <= in (%s)\n' "$out_sz" "$in_sz" >&2
  exit 1
}
