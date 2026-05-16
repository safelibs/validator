#!/usr/bin/env bash
# @testcase: usage-exif-r21-cli-xml-maker-note-byte-count
# @title: exif --xml-output reports MakerNote as 904 bytes of undefined data
# @description: Runs exif --xml-output on the Canon fixture and asserts the captured XML contains the literal "<Maker_Note>904 bytes undefined data</Maker_Note>" element - locking in libexif's XML rendering of MakerNote as an opaque byte blob along with the precise byte count for this fixture, distinct from prior MakerNote source-only and machine-readable coverage.
# @timeout: 60
# @tags: usage, exif, xml-output, maker-note, r21
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/out.xml" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out.xml" '<Maker_Note>904 bytes undefined data</Maker_Note>'
