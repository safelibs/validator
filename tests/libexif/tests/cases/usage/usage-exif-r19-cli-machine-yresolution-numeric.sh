#!/usr/bin/env bash
# @testcase: usage-exif-r19-cli-machine-yresolution-numeric
# @title: exif -m -t YResolution emits a digit-bearing machine-readable line
# @description: Runs exif -m -t YResolution on the canon fixture and asserts the captured stdout contains at least one decimal digit (libexif renders the YResolution rational with its integer numerator in machine output on the canon fixture), exercising the machine-readable single-tag rendering for IFD0 YResolution.
# @timeout: 60
# @tags: usage, exif, machine, yresolution, r19
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif -m -t YResolution "$img" >"$tmpdir/out" 2>"$tmpdir/err"

size=$(wc -c <"$tmpdir/out")
if [[ "$size" -le 0 ]]; then
  echo 'no output from -m -t YResolution' >&2
  cat "$tmpdir/err" >&2
  exit 1
fi
if ! LC_ALL=C grep -Eq '[0-9]' "$tmpdir/out"; then
  echo 'expected at least one digit in YResolution machine output' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
