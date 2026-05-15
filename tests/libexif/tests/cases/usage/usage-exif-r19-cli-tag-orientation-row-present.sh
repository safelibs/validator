#!/usr/bin/env bash
# @testcase: usage-exif-r19-cli-tag-orientation-row-present
# @title: exif --tag=Orientation pretty output includes a Tag and a Value line
# @description: Runs exif --tag=Orientation on the canon fixture and asserts the pretty-printed output contains both a "Tag:" header line and a "Value:" line with non-empty payload, exercising libexif's single-tag pretty rendering for IFD0 Orientation through the exif CLI.
# @timeout: 60
# @tags: usage, exif, orientation, pretty, r19
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=Orientation "$img" >"$tmpdir/out" 2>"$tmpdir/err"

LC_ALL=C grep -Eq '^[[:space:]]*Tag:' "$tmpdir/out" || {
  echo 'missing Tag: line in --tag=Orientation output' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
value_line=$(LC_ALL=C grep -E '^[[:space:]]*Value:' "$tmpdir/out" | head -n1 || true)
if [[ -z "$value_line" ]]; then
  echo 'missing Value: line' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
payload=${value_line#*Value:}
payload=${payload# }
if [[ -z "$payload" ]]; then
  echo 'Value: payload is empty' >&2
  exit 1
fi
