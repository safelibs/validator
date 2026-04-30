#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-fnumber-ifd-exif-value
# @title: exif --tag=FNumber --ifd=EXIF pins f/2.8
# @description: Runs the exif client with --tag=FNumber --ifd=EXIF against the canon fixture and verifies the EXIF-scoped readout reports the F-Number label with the exact f/2.8 value, while a parallel probe scoped to --ifd=0 fails because the tag does not live in IFD 0.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-fnumber-ifd-exif-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# EXIF IFD probe must succeed and pin the value
exif --tag=FNumber --ifd=EXIF "$img" >"$tmpdir/exif.out"
validator_assert_contains "$tmpdir/exif.out" 'F-Number'
validator_assert_contains "$tmpdir/exif.out" 'Value: f/2.8'

# IFD 0 probe must fail because FNumber lives in the EXIF IFD
set +e
exif --tag=FNumber --ifd=0 "$img" >"$tmpdir/zero.stdout" 2>"$tmpdir/zero.stderr"
rc=$?
set -e

if (( rc == 0 )); then
  printf 'expected --ifd=0 --tag=FNumber to fail, got rc=0\n' >&2
  cat "$tmpdir/zero.stdout" "$tmpdir/zero.stderr" >&2
  exit 1
fi

cat "$tmpdir/zero.stdout" "$tmpdir/zero.stderr" >"$tmpdir/zero.all"
if ! grep -Eq "does not contain tag 'FNumber'|FNumber.*not found|not found.*FNumber" "$tmpdir/zero.all"; then
  printf 'expected an FNumber-not-in-IFD-0 diagnostic\n' >&2
  cat "$tmpdir/zero.all" >&2
  exit 1
fi
# Make sure the EXIF IFD value did NOT leak into the IFD 0 stdout
if grep -q 'f/2.8' "$tmpdir/zero.stdout"; then
  printf 'unexpected f/2.8 value emitted on --ifd=0 probe\n' >&2
  cat "$tmpdir/zero.stdout" >&2
  exit 1
fi
