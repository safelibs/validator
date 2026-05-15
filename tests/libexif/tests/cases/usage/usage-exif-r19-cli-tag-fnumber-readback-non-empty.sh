#!/usr/bin/env bash
# @testcase: usage-exif-r19-cli-tag-fnumber-readback-non-empty
# @title: exif --tag=FNumber pretty output Value line is a non-empty f-stop string
# @description: Runs exif --tag=FNumber on the canon fixture and asserts the captured pretty output contains a "Value:" line whose trimmed payload is non-empty and contains a digit (libexif renders the FNumber rational as a decimal-bearing string), exercising the EXIF-IFD FNumber rational tag rendering path.
# @timeout: 60
# @tags: usage, exif, fnumber, rational, r19
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=FNumber "$img" >"$tmpdir/out" 2>"$tmpdir/err"
value_line=$(LC_ALL=C grep -E '^[[:space:]]*Value:' "$tmpdir/out" | head -n1 || true)
if [[ -z "$value_line" ]]; then
  echo 'missing Value: line in --tag=FNumber' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
payload=${value_line#*Value:}
payload=${payload# }
if [[ -z "$payload" ]]; then
  echo 'empty FNumber value' >&2
  exit 1
fi
case "$payload" in
  *[0-9]*) ;;
  *)
    printf 'expected at least one digit in FNumber value, got: %s\n' "$payload" >&2
    exit 1
    ;;
esac
