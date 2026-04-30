#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-without-ifd-dual-probe
# @title: exif --tag without --ifd resolves IFD 0 then EXIF tags
# @description: Runs the exif client with --tag and no --ifd argument, first against the IFD 0 Make tag and then against the EXIF-IFD FNumber tag, verifying the client transparently locates each tag in its native IFD and reports Canon for Make and f/2.8 for FNumber, exactly matching the explicitly scoped --ifd readouts.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-without-ifd-dual-probe"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Make lives in IFD 0; --tag without --ifd must still find it
exif --tag=Make "$img" >"$tmpdir/make.no-ifd"
validator_assert_contains "$tmpdir/make.no-ifd" 'Value: Canon'

# FNumber lives in the EXIF IFD; --tag without --ifd must still find it
exif --tag=FNumber "$img" >"$tmpdir/fnumber.no-ifd"
validator_assert_contains "$tmpdir/fnumber.no-ifd" 'Value: f/2.8'

# Cross-check against explicit --ifd readouts for byte equality
exif --tag=Make --ifd=0 "$img" >"$tmpdir/make.ifd0"
exif --tag=FNumber --ifd=EXIF "$img" >"$tmpdir/fnumber.ifd-exif"

if ! cmp -s "$tmpdir/make.no-ifd" "$tmpdir/make.ifd0"; then
  printf 'unscoped --tag=Make diverged from --ifd=0 readout\n' >&2
  diff -u "$tmpdir/make.ifd0" "$tmpdir/make.no-ifd" >&2 || true
  exit 1
fi

if ! cmp -s "$tmpdir/fnumber.no-ifd" "$tmpdir/fnumber.ifd-exif"; then
  printf 'unscoped --tag=FNumber diverged from --ifd=EXIF readout\n' >&2
  diff -u "$tmpdir/fnumber.ifd-exif" "$tmpdir/fnumber.no-ifd" >&2 || true
  exit 1
fi
