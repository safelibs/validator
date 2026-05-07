#!/usr/bin/env bash
# @testcase: usage-exif-r12-cli-machine-readable-make-canon
# @title: exif --machine-readable --tag=Make returns "Canon" with no surrounding text
# @description: Reads the Make tag in --machine-readable mode and verifies the entire output is exactly "Canon" plus a single trailing newline, asserting libexif emits the bare ASCII value with no annotation in machine-readable mode.
# @timeout: 60
# @tags: usage, machine-readable, make
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=Make "$img" >"$tmpdir/out"
read -r value <"$tmpdir/out"
if [[ "$value" != "Canon" ]]; then
  printf 'expected Make=Canon, got: %s\n' "$value" >&2
  exit 1
fi

lines=$(wc -l <"$tmpdir/out")
if (( lines != 1 )); then
  printf 'expected exactly 1 line, got %d\n' "$lines" >&2
  exit 1
fi
