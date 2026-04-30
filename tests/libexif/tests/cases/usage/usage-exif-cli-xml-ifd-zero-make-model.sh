#!/usr/bin/env bash
# @testcase: usage-exif-cli-xml-ifd-zero-make-model
# @title: exif --xml-output --ifd=0 emits Make and Model
# @description: Restricts XML output to IFD 0 with --xml-output --ifd=0 and verifies the wrapper plus Manufacturer and Model elements for the canon fixture.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output --ifd=0 "$img" >"$tmpdir/out.xml"
validator_assert_contains "$tmpdir/out.xml" "<exif>"
validator_assert_contains "$tmpdir/out.xml" "</exif>"
validator_assert_contains "$tmpdir/out.xml" "<Manufacturer>Canon</Manufacturer>"
validator_assert_contains "$tmpdir/out.xml" "<Model>Canon PowerShot S70</Model>"
validator_assert_contains "$tmpdir/out.xml" "<Date_and_Time>2009:10:10 16:42:32</Date_and_Time>"
