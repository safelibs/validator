#!/usr/bin/env bash
# @testcase: usage-exif-r12-cli-list-tags-includes-make-row
# @title: exif -l -m emits a tab-separated row whose first field is "0x010f" and second is "Make"
# @description: Renders the --list-tags grid in --machine-readable mode and verifies a row "0x010f<TAB>Make<TAB>..." appears, asserting libexif's static tag table contains the Make entry with its canonical hex id and symbolic name in the tab-delimited machine-readable layout.
# @timeout: 60
# @tags: usage, list-tags, make
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --list-tags --machine-readable "$img" >"$tmpdir/out"
grep -P '^0x010f\tMake\t' "$tmpdir/out" >/dev/null
