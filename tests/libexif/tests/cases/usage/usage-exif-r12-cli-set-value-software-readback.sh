#!/usr/bin/env bash
# @testcase: usage-exif-r12-cli-set-value-software-readback
# @title: exif --set-value writes Software into IFD 0 and reads it back verbatim
# @description: Sets the Software tag in IFD 0 to a short ASCII string, writes a new JPEG via --output, and verifies the machine-readable readback returns the same string, asserting the libexif ASCII writer for the Software (0x0131) tag.
# @timeout: 60
# @tags: usage, metadata, set-value, software
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --tag=Software --ifd=0 --set-value='r12-pipeline' --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"

exif --tag=Software --machine-readable "$tmpdir/out.jpg" >"$tmpdir/value"
read -r value <"$tmpdir/value"
if [[ "$value" != "r12-pipeline" ]]; then
  printf 'expected Software=r12-pipeline, got: %s\n' "$value" >&2
  exit 1
fi
