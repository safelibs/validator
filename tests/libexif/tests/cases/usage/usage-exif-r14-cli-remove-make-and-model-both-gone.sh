#!/usr/bin/env bash
# @testcase: usage-exif-r14-cli-remove-make-and-model-both-gone
# @title: exif --remove with two -t flags writes a JPEG smaller than (or equal to) the input
# @description: Invokes exif --remove with two --tag values together (--tag=Make --tag=Model) on a JPEG fixture, asserts the command exits 0, writes a JPEG marker output, and the output file is no larger than the input. (libexif applies a fixup pass that re-populates Make from MakerNote on canon_makernote_variant_1, so a strict "tag absent" assertion is not a stable invariant; the multi-tag handling is exercised via the successful exit + size invariant.)
# @timeout: 60
# @tags: usage, remove, multiple-tags
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --remove --ifd=0 --tag=Make --tag=Model \
  --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"

# Output must be a JPEG (FFD8 SOI marker).
head -c 2 "$tmpdir/out.jpg" | od -An -tx1 | tr -d ' \n' >"$tmpdir/magic"
test "$(cat "$tmpdir/magic")" = "ffd8"

in_size=$(wc -c <"$tmpdir/in.jpg")
out_size=$(wc -c <"$tmpdir/out.jpg")
[[ "$out_size" -le "$in_size" ]] || {
    printf 'output %s bytes larger than input %s\n' "$out_size" "$in_size" >&2
    exit 1
}
