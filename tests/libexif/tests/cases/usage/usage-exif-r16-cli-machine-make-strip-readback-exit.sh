#!/usr/bin/env bash
# @testcase: usage-exif-r16-cli-machine-make-strip-readback-exit
# @title: exif --remove --tag Make then --machine-readable Make returns non-zero
# @description: Removes the Make tag from a copy of the canon fixture and verifies that --output is a valid JPEG no larger than the input, then asserts a subsequent --machine-readable --tag=Make on the stripped image exits non-zero (the tag value is no longer queryable as a stand-alone machine value), without asserting Make itself has disappeared from full dumps (libexif's MakerNote fixup can restore it).
# @timeout: 60
# @tags: usage, remove, make
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --remove --tag=Make --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/write.log"
validator_require_file "$tmpdir/out.jpg"
file -b "$tmpdir/out.jpg" | grep -qi JPEG

in_sz=$(wc -c <"$tmpdir/in.jpg")
out_sz=$(wc -c <"$tmpdir/out.jpg")
[[ "$out_sz" -le "$in_sz" ]] || {
  printf 'expected out (%s) <= in (%s)\n' "$out_sz" "$in_sz" >&2
  exit 1
}

set +e
exif --machine-readable --tag=Make "$tmpdir/out.jpg" >"$tmpdir/mr.out" 2>"$tmpdir/mr.err"
rc=$?
set -e
if [[ $rc -eq 0 ]]; then
  printf 'expected non-zero exit reading Make after --remove, got rc=%d\n' "$rc" >&2
  cat "$tmpdir/mr.out" >&2
  exit 1
fi
