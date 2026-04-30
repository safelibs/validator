#!/usr/bin/env bash
# @testcase: usage-pngquant-strip-metadata-verify-png
# @title: pngquant --strip removes ancillary metadata
# @description: Adds a tEXt chunk with a known marker to basn2c08.png via pnmtopng -text, runs pngquant --strip, and verifies the resulting PNG no longer contains the tEXt marker while remaining a valid PNG.
# @timeout: 180
# @tags: usage, image, png, metadata
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-strip-metadata-verify-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

# Re-encode the fixture with an injected tEXt chunk so we have ancillary
# metadata to strip. pnmtopng -text takes a file with keyword/text pairs:
# each entry is two lines (keyword, then the text).
pngtopam "$png" >"$tmpdir/in.pam"
pamtopnm "$tmpdir/in.pam" >"$tmpdir/in.ppm"
cat >"$tmpdir/text.txt" <<'TXT'
Comment
validator-strip-marker-7Q3R
TXT
pnmtopng -text "$tmpdir/text.txt" "$tmpdir/in.ppm" \
  >"$tmpdir/with_meta.png"
file "$tmpdir/with_meta.png" | tee "$tmpdir/meta.file"
validator_assert_contains "$tmpdir/meta.file" 'PNG image data'

# Confirm the marker is present in the input (sanity).
if ! grep -aFq 'validator-strip-marker-7Q3R' "$tmpdir/with_meta.png"; then
  printf 'expected metadata marker missing from prepared input\n' >&2
  exit 1
fi

pngquant --strip --force --output "$tmpdir/out.png" 256 "$tmpdir/with_meta.png"
file "$tmpdir/out.png" | tee "$tmpdir/out.file"
validator_assert_contains "$tmpdir/out.file" 'PNG image data'

# After --strip, the comment must be gone from the output stream.
if grep -aFq 'validator-strip-marker-7Q3R' "$tmpdir/out.png"; then
  printf 'pngquant --strip did not remove text metadata\n' >&2
  exit 1
fi

# Pixel content must still decode at the original 32x32 dimensions.
pngtopam "$tmpdir/out.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '32 by 32'
