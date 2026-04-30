#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-readable-associative-array
# @title: exif --machine-readable populates a bash associative array
# @description: Runs the exif client with --machine-readable against the canon fixture, parses the tab-delimited stream into a bash associative array indexed by tag name, and verifies that array lookups for Manufacturer, Model, Color Space, Orientation, and Compression each yield the expected canonical literal values, demonstrating the machine-readable format is robust enough for shell-side declare -A consumers.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-readable-associative-array"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable "$img" >"$tmpdir/raw"

declare -A tags=()
while IFS=$'\t' read -r key value rest; do
  [[ -z "$key" ]] && continue
  if [[ -n "${rest-}" ]]; then
    value="${value}"$'\t'"${rest}"
  fi
  tags["$key"]="$value"
done <"$tmpdir/raw"

if (( ${#tags[@]} == 0 )); then
  printf 'expected at least one machine-readable record, parsed zero entries\n' >&2
  cat "$tmpdir/raw" >&2
  exit 1
fi

check() {
  local key=$1
  local expected=$2
  local actual="${tags[$key]-__missing__}"
  if [[ "$actual" == '__missing__' ]]; then
    printf 'associative array missing key: %s\n' "$key" >&2
    printf 'parsed keys: %s\n' "${!tags[*]}" >&2
    exit 1
  fi
  if [[ "$actual" != "$expected" ]]; then
    printf 'associative array %s mismatch: got %q expected %q\n' \
      "$key" "$actual" "$expected" >&2
    exit 1
  fi
}

check 'Manufacturer' 'Canon'
check 'Model' 'Canon PowerShot S70'
check 'Color Space' 'sRGB'
check 'Orientation' 'Right-top'
check 'Compression' 'JPEG compression'
