#!/usr/bin/env bash
# @testcase: usage-exif-r15-cli-machine-readable-x-resolution-ifd-zero
# @title: exif --ifd=0 --machine-readable --tag=XResolution emits exactly "180"
# @description: Reads the XResolution tag scoped to IFD 0 in --machine-readable mode and verifies the output is exactly the literal string "180" plus a single newline with line count == 1, asserting libexif emits the bare formatted RATIONAL (180/1) without surrounding annotation when scoped to a single IFD.
# @timeout: 60
# @tags: usage, machine-readable, x-resolution, ifd-zero
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=0 --machine-readable --tag=XResolution "$img" >"$tmpdir/out"
read -r value <"$tmpdir/out"
if [[ "$value" != "180" ]]; then
  printf 'expected XResolution=180, got: %s\n' "$value" >&2
  exit 1
fi

lines=$(wc -l <"$tmpdir/out")
if (( lines != 1 )); then
  printf 'expected exactly 1 line, got %d\n' "$lines" >&2
  exit 1
fi
