#!/usr/bin/env bash
# @testcase: usage-exif-r18-cli-tag-model-readback-non-empty
# @title: exif --machine-readable --tag=Model emits a non-empty trimmed value line
# @description: Reads the Model tag from the canon fixture via exif --machine-readable --tag=Model and asserts the single-line value, after trimming, is non-empty and matches a printable-ASCII shape (no NULs, no leading/trailing whitespace fail), exercising libexif's ASCII readback for IFD0 Model through the machine-readable path.
# @timeout: 60
# @tags: usage, exif, model, machine-readable, r18
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=Model "$img" >"$tmpdir/out" 2>"$tmpdir/err"
read -r value <"$tmpdir/out" || true
if [[ -z "${value:-}" ]]; then
  echo 'Model readback was empty' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
if ! LC_ALL=C printf '%s' "$value" | grep -Eq '^[[:print:]]+$'; then
  printf 'Model value not printable ASCII, got: %s\n' "$value" >&2
  exit 1
fi
