#!/usr/bin/env bash
# @testcase: usage-exif-r19-cli-extract-thumbnail-write-then-strip
# @title: exif --remove-thumbnail rewrites the canon JPEG to a smaller file
# @description: Runs exif --remove-thumbnail --output on the canon fixture and asserts the rewritten JPEG starts with the SOI marker FFD8, exists on disk with positive size, and is strictly smaller than the original (libexif removes the embedded thumbnail bytes from the EXIF block), exercising the libexif thumbnail-strip writeout path.
# @timeout: 60
# @tags: usage, exif, thumbnail, strip, r19
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

cp -a "$img" "$tmpdir/in.jpg"
exif --remove-thumbnail --output="$tmpdir/stripped.jpg" "$tmpdir/in.jpg" >"$tmpdir/log" 2>"$tmpdir/err"
validator_require_file "$tmpdir/stripped.jpg"

orig=$(wc -c <"$img")
out=$(wc -c <"$tmpdir/stripped.jpg")
if [[ "$out" -le 0 ]]; then
  echo 'stripped output is empty' >&2
  exit 1
fi
soi=$(head -c2 "$tmpdir/stripped.jpg" | od -An -tx1 | tr -d ' \n')
if [[ "$soi" != 'ffd8' ]]; then
  printf 'expected SOI ffd8, got %s\n' "$soi" >&2
  exit 1
fi
if [[ "$out" -ge "$orig" ]]; then
  printf 'expected stripped size < original (%s), got %s\n' "$orig" "$out" >&2
  exit 1
fi
