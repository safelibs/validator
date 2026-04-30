#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-ifd-gps-empty
# @title: exif --machine-readable --ifd=GPS reports empty GPS IFD
# @description: Runs the exif client with --machine-readable --ifd=GPS against the canon fixture which has no GPS metadata and verifies the stream emits only the synthetic ThumbnailSize entry without EXIF or IFD 0 tags.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-ifd-gps-empty"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --ifd=GPS "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" $'ThumbnailSize\t4'

for unwanted in 'Manufacturer' 'Model' 'F-Number' 'Color Space' 'Exif Version' 'FlashPixVersion'; do
  if grep -q "^${unwanted}" "$tmpdir/out"; then
    printf 'unexpected entry %s in GPS IFD stream\n' "$unwanted" >&2
    cat "$tmpdir/out" >&2
    exit 1
  fi
done
