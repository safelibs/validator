#!/usr/bin/env bash
# @testcase: usage-exif-r15-cli-machine-readable-resolution-unit-ifd-zero
# @title: exif --ifd=0 --machine-readable --tag=ResolutionUnit emits exactly "Inch"
# @description: Reads the ResolutionUnit tag scoped to IFD 0 in --machine-readable mode and verifies the output is exactly the literal string "Inch" plus a single newline with line count == 1, asserting libexif maps the standard ResolutionUnit value 2 to its conventional "Inch" label without surrounding annotation when scoped to IFD 0.
# @timeout: 60
# @tags: usage, machine-readable, resolution-unit, ifd-zero
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=0 --machine-readable --tag=ResolutionUnit "$img" >"$tmpdir/out"
read -r value <"$tmpdir/out"
if [[ "$value" != "Inch" ]]; then
  printf 'expected ResolutionUnit=Inch, got: %s\n' "$value" >&2
  exit 1
fi

lines=$(wc -l <"$tmpdir/out")
if (( lines != 1 )); then
  printf 'expected exactly 1 line, got %d\n' "$lines" >&2
  exit 1
fi
