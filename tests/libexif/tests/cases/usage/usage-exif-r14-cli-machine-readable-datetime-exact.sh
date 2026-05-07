#!/usr/bin/env bash
# @testcase: usage-exif-r14-cli-machine-readable-datetime-exact
# @title: exif --machine-readable --tag=DateTime emits exactly "2009:10:10 16:42:32"
# @description: Reads the DateTime tag in --machine-readable mode and verifies the output is exactly the literal string "2009:10:10 16:42:32" plus a single newline with line count == 1, asserting libexif emits the bare DateTime ASCII without surrounding annotation in machine-readable mode.
# @timeout: 60
# @tags: usage, machine-readable, datetime
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=DateTime "$img" >"$tmpdir/out"
read -r value <"$tmpdir/out"
if [[ "$value" != "2009:10:10 16:42:32" ]]; then
  printf 'expected DateTime=2009:10:10 16:42:32, got: %s\n' "$value" >&2
  exit 1
fi

lines=$(wc -l <"$tmpdir/out")
if (( lines != 1 )); then
  printf 'expected exactly 1 line, got %d\n' "$lines" >&2
  exit 1
fi
