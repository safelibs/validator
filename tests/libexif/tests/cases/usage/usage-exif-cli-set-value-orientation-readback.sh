#!/usr/bin/env bash
# @testcase: usage-exif-cli-set-value-orientation-readback
# @title: exif --set-value rewrites Orientation Short tag
# @description: Uses exif --set-value with --ifd=0 --tag=Orientation to replace the SHORT-typed Orientation entry on a copy of the canon fixture (4 -> 1, "Bottom-left" to "Top-left") and reads the new value back from the rewritten JPEG. The original fixture is verified untouched and the rewritten copy must report Orientation=1 with the human-readable "Top-left" label, pinning libexif's set-value path for non-ASCII (Short) tags on Ubuntu 24.04.
# @timeout: 120
# @tags: usage, metadata, set-value
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-set-value-orientation-readback"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Sanity: original fixture reports Orientation 'Right-top' (value 8 in the spec)
exif --tag=Orientation --ifd=0 "$img" >"$tmpdir/before.out"
validator_assert_contains "$tmpdir/before.out" 'Value: Right-top'

cp "$img" "$tmpdir/source.jpg"
exif --ifd=0 --tag=Orientation --set-value=1 \
  --output="$tmpdir/edited.jpg" "$tmpdir/source.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" 'Wrote file'
validator_require_file "$tmpdir/edited.jpg"

# Original fixture must remain untouched
exif --tag=Orientation --ifd=0 "$img" >"$tmpdir/after-original.out"
validator_assert_contains "$tmpdir/after-original.out" 'Value: Right-top'

# Rewritten copy must report Orientation=1 / Top-left
exif --tag=Orientation --ifd=0 "$tmpdir/edited.jpg" >"$tmpdir/edited.out"
validator_assert_contains "$tmpdir/edited.out" 'Value: Top-left'
validator_assert_contains "$tmpdir/edited.out" "Format: 3 ('Short')"

# Machine-readable readback prints just the human label
exif -m --tag=Orientation --ifd=0 "$tmpdir/edited.jpg" >"$tmpdir/edited.machine"
machine_value=$(tr -d '\r\n' <"$tmpdir/edited.machine")
if [[ "$machine_value" != 'Top-left' ]]; then
  printf 'expected machine-readable Top-left, got %q\n' "$machine_value" >&2
  exit 1
fi
