#!/usr/bin/env bash
# @testcase: usage-exif-r18-cli-tag-make-value-canon-prefix
# @title: exif --tag=Make pretty output emits a Value line starting with Canon
# @description: Runs exif --tag=Make against the canon fixture and asserts the pretty-printed output contains a "Value:" line whose trimmed payload starts with the literal manufacturer string "Canon", exercising libexif's ASCII tag value rendering for IFD0 Make in human-readable mode.
# @timeout: 60
# @tags: usage, exif, make, r18
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=Make "$img" >"$tmpdir/out" 2>"$tmpdir/err"

value_line=$(LC_ALL=C grep -E '^[[:space:]]*Value:' "$tmpdir/out" | head -n1 || true)
if [[ -z "$value_line" ]]; then
  echo 'no Value: line in exif --tag=Make output' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
payload=${value_line#*Value:}
payload=${payload# }
case "$payload" in
  Canon*) ;;
  *)
    printf 'expected Value: to begin with Canon, got: %s\n' "$payload" >&2
    exit 1
    ;;
esac
