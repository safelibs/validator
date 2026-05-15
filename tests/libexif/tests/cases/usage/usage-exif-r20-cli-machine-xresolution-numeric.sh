#!/usr/bin/env bash
# @testcase: usage-exif-r20-cli-machine-xresolution-numeric
# @title: exif -m -t XResolution on canon fixture emits a numeric token
# @description: Runs exif --machine-readable --tag=XResolution on the canon fixture and asserts the captured output's first non-blank token starts with a digit and contains a numeric resolution value (libexif renders the rational as a decimal like "180" or "180.00"), exercising libexif's machine-readable tag rendering for IFD0 XResolution.
# @timeout: 60
# @tags: usage, exif, machine-readable, xresolution, numeric, r20
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=XResolution "$img" >"$tmpdir/out" 2>"$tmpdir/err"

# Strip whitespace and assert it starts with a digit.
val=$(LC_ALL=C tr -d '[:space:]' <"$tmpdir/out")
if [[ -z "$val" ]]; then
    echo 'expected non-empty XResolution value' >&2
    cat "$tmpdir/err" >&2
    exit 1
fi
[[ "$val" =~ ^[0-9] ]] || {
    printf 'expected numeric XResolution, got %q\n' "$val" >&2
    exit 1
}
