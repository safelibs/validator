#!/usr/bin/env bash
# @testcase: usage-exif-cli-no-xmp-block-canon-fixture
# @title: exif against canon fixture exposes no XMP-derived tags
# @description: Runs the exif client against the canon fixture in machine-readable mode and verifies the streamed records contain none of the XMP-derived field names a dependent client might expect to see when an XMP packet is present (XMPToolkit, dc:creator, xmp:CreatorTool, photoshop:DateCreated). libexif itself does not parse XMP, but a fixture that carries an XMP APP1 segment can cause clients to scrape XMP names out of the JPEG; this testcase pins the canon fixture as XMP-free so other testcases can rely on that.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-no-xmp-block-canon-fixture"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# A regular machine-readable dump must not surface any XMP-style names.
exif --machine-readable "$img" >"$tmpdir/machine.out"

# Sanity: the dump itself is non-empty so the negative checks below are meaningful.
size=$(stat -c '%s' "$tmpdir/machine.out")
if (( size <= 0 )); then
  printf 'expected non-empty machine-readable dump\n' >&2
  exit 1
fi

for unwanted in 'XMPToolkit' 'xmp:CreatorTool' 'dc:creator' 'photoshop:DateCreated' 'x:xmpmeta'; do
  if grep -Fq -- "$unwanted" "$tmpdir/machine.out"; then
    printf 'unexpected XMP-derived field %s in machine-readable dump\n' "$unwanted" >&2
    cat "$tmpdir/machine.out" >&2
    exit 1
  fi
done

# Sanity: the EXIF-side data the fixture is known to carry is still present.
validator_assert_contains "$tmpdir/machine.out" $'Manufacturer\tCanon'

# Cross-check: a raw byte scan of the fixture must not contain an XMP namespace
# marker. libexif clients sometimes mmap the JPEG separately, so confirming the
# absence of "http://ns.adobe.com/xap/" rules out an XMP APP1 segment entirely.
if grep -Fq -- 'http://ns.adobe.com/xap/' "$img"; then
  printf 'canon fixture unexpectedly carries an XMP APP1 namespace marker\n' >&2
  exit 1
fi
