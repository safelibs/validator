#!/usr/bin/env bash
# @testcase: usage-exif-r15-cli-set-value-software-then-readback-machine
# @title: exif --set-value writes Software in IFD 0 and reads it back verbatim
# @description: Sets the Software tag in IFD 0 to a short ASCII string with --set-value, writes the new JPEG via --output, and verifies the --machine-readable readback returns exactly that string with line count == 1, asserting the libexif ASCII writer for the Software (0x0131) tag round-trips through the CLI without trailing-NUL or annotation noise.
# @timeout: 60
# @tags: usage, set-value, software
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --tag=Software --ifd=0 --set-value='ValidatorR15SW' \
  --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"

exif --tag=Software --machine-readable "$tmpdir/out.jpg" >"$tmpdir/value"
read -r value <"$tmpdir/value"
if [[ "$value" != "ValidatorR15SW" ]]; then
  printf 'expected Software=ValidatorR15SW, got: %s\n' "$value" >&2
  exit 1
fi

lines=$(wc -l <"$tmpdir/value")
if (( lines != 1 )); then
  printf 'expected exactly 1 line, got %d\n' "$lines" >&2
  exit 1
fi
