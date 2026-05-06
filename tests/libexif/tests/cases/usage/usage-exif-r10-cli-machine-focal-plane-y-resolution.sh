#!/usr/bin/env bash
# @testcase: usage-exif-r10-cli-machine-focal-plane-y-resolution
# @title: exif machine FocalPlaneYResolution emits the rational scalar
# @description: Reads the focal-plane Y resolution tag in machine-readable form against the canon fixture and verifies a single-line tab-free numeric output with the 2253 prefix libexif emits from the stored Rational, complementing the existing FocalPlaneXResolution machine probe so callers can rely on both axes being consumable in scripts.
# @timeout: 60
# @tags: usage, metadata, focal-plane
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=FocalPlaneYResolution "$img" >"$tmpdir/out"

line_count=$(wc -l <"$tmpdir/out")
if (( line_count != 1 )); then
  printf 'expected exactly 1 line, got %d\n' "$line_count" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi

# Output must contain the 2253 prefix and start with a digit
read -r value <"$tmpdir/out"
if [[ ! "$value" =~ ^2253 ]]; then
  printf 'expected value to start with 2253, got: %s\n' "$value" >&2
  exit 1
fi

# Machine-readable scoped scalar must not include any tab character
if grep -qP '\t' "$tmpdir/out"; then
  printf 'unexpected tab in scoped scalar output\n' >&2
  od -An -c "$tmpdir/out" | head >&2
  exit 1
fi
