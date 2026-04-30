#!/usr/bin/env bash
# @testcase: usage-exif-cli-set-value-machine-readable-bytes
# @title: exif --set-value cross-validated via --machine-readable bytes
# @description: Rewrites the Make tag on a copy of the canon fixture with --set-value, reads the new value back through --tag=Make, then runs --machine-readable --tag=Make against the rewritten file and compares the exact byte sequence on stdout to the literal new value to confirm the rewrite is observable through both rendering modes.
# @timeout: 180
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-set-value-machine-readable-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

new_value='SafelibsCam'

cp "$img" "$tmpdir/source.jpg"
exif --ifd=0 --tag=Make --set-value="$new_value" \
  --output="$tmpdir/edited.jpg" "$tmpdir/source.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" 'Wrote file'
validator_require_file "$tmpdir/edited.jpg"

# Pretty readback should report the new manufacturer string
exif --tag=Make "$tmpdir/edited.jpg" >"$tmpdir/pretty.out"
validator_assert_contains "$tmpdir/pretty.out" "Value: $new_value"

# Machine-readable readback must produce exactly the new value followed by a newline
exif --machine-readable --tag=Make "$tmpdir/edited.jpg" >"$tmpdir/machine.out"
expected="$tmpdir/expected"
printf '%s\n' "$new_value" >"$expected"

if ! cmp -s "$tmpdir/machine.out" "$expected"; then
  printf 'machine-readable bytes for rewritten Make tag did not match expected literal\n' >&2
  od -An -c "$tmpdir/machine.out" >&2
  od -An -c "$expected" >&2
  exit 1
fi

# Original fixture must still report Canon to confirm the rewrite was scoped to the copy
exif --machine-readable --tag=Make "$img" >"$tmpdir/original.out"
expected_original="$tmpdir/expected_original"
printf 'Canon\n' >"$expected_original"
if ! cmp -s "$tmpdir/original.out" "$expected_original"; then
  printf 'original fixture machine-readable Make value diverged from Canon literal\n' >&2
  od -An -c "$tmpdir/original.out" >&2
  exit 1
fi
