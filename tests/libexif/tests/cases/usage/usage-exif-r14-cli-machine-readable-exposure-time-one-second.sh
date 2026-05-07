#!/usr/bin/env bash
# @testcase: usage-exif-r14-cli-machine-readable-exposure-time-one-second
# @title: exif --machine-readable --tag=ExposureTime emits exactly "1 sec."
# @description: Reads the ExposureTime tag in --machine-readable mode and verifies the output is exactly the literal string "1 sec." plus a single newline with line count == 1, asserting libexif emits the formatted RATIONAL value without surrounding annotation in machine-readable mode.
# @timeout: 60
# @tags: usage, machine-readable, exposure-time
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=ExposureTime "$img" >"$tmpdir/out"
read -r value <"$tmpdir/out"
if [[ "$value" != "1 sec." ]]; then
  printf 'expected ExposureTime=1 sec., got: %s\n' "$value" >&2
  exit 1
fi

lines=$(wc -l <"$tmpdir/out")
if (( lines != 1 )); then
  printf 'expected exactly 1 line, got %d\n' "$lines" >&2
  exit 1
fi
