#!/usr/bin/env bash
# @testcase: usage-exif-r20-cli-remove-orientation-output-jpeg-magic
# @title: exif --remove --tag=Orientation produces a JPEG starting with the SOI marker
# @description: Copies the canon fixture, runs exif --remove --tag=Orientation --output to rewrite the JPEG without the Orientation tag, then asserts the rewritten file starts with the JPEG SOI marker bytes FFD8 - locking in libexif's tag-removal write path preserving JPEG container framing.
# @timeout: 60
# @tags: usage, exif, remove, orientation, jpeg-magic, r20
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

cp -a "$img" "$tmpdir/in.jpg"
exif --remove --tag=Orientation --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/log" 2>"$tmpdir/err"
validator_require_file "$tmpdir/out.jpg"

soi=$(head -c2 "$tmpdir/out.jpg" | od -An -tx1 | tr -d ' \n')
[[ "$soi" == "ffd8" ]] || {
    printf 'expected SOI ffd8, got %s\n' "$soi" >&2
    exit 1
}
