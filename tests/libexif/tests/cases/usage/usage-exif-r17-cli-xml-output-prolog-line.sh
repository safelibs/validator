#!/usr/bin/env bash
# @testcase: usage-exif-r17-cli-xml-output-prolog-line
# @title: exif --xml-output emits canonical XML declaration prologue
# @description: Runs exif --xml-output on the canon fixture and asserts the first line is the XML declaration starting with "<?xml ", exercising libexif's XML serialiser prologue (independent of any element-name assertion).
# @timeout: 60
# @tags: usage, exif, xml, prologue
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/out.xml"
read -r first <"$tmpdir/out.xml"
case "$first" in
  '<?xml '*)
    ;;
  *)
    printf 'expected XML prolog on first line, got: %s\n' "$first" >&2
    exit 1
    ;;
esac
