#!/usr/bin/env bash
# @testcase: usage-exif-r14-cli-set-value-make-then-readback
# @title: exif --set-value writes Make in IFD 0 and reads it back verbatim
# @description: Sets the Make tag in IFD 0 to a short ASCII string with --set-value, writes the new JPEG via --output, and verifies the --machine-readable readback returns exactly that string, asserting the libexif ASCII writer for the Make (0x010F) tag round-trips through the CLI.
# @timeout: 60
# @tags: usage, set-value, make
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --tag=Make --ifd=0 --set-value='ValidatorR14Make' \
  --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"

exif --tag=Make --machine-readable "$tmpdir/out.jpg" >"$tmpdir/value"
read -r value <"$tmpdir/value"
if [[ "$value" != "ValidatorR14Make" ]]; then
  printf 'expected Make=ValidatorR14Make, got: %s\n' "$value" >&2
  exit 1
fi
