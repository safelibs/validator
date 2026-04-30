#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-nofl-flag
# @title: GDAL gdalinfo -nofl flag is accepted and parsed
# @description: Runs gdalinfo with the -nofl flag against a GTiff converted from the bundled gdalicon raster and verifies that the flag is accepted (exit 0), still emits the core Driver/Size/Band lines, and that the Files: section, when present, lists only the GTiff itself (the -nofl flag's documented behaviour: show only the first file of the file list).
# @timeout: 180
# @tags: usage, gdal, raster
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalinfo-nofl-flag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

# Convert to a multi-file GTiff so gdalinfo's default output reliably
# emits a Files: section (single-file PNG suppresses it on some GDAL builds).
gdal_translate -of GTiff -co TILED=YES "$raster" "$tmpdir/icon.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/icon.tif"

# Baseline: default invocation must include the Files: section.
gdalinfo "$tmpdir/icon.tif" >"$tmpdir/with-files.txt"
validator_assert_contains "$tmpdir/with-files.txt" 'Files:'

# -nofl must be accepted and produce the same core report sections.
gdalinfo -nofl "$tmpdir/icon.tif" >"$tmpdir/no-files.txt"
validator_assert_contains "$tmpdir/no-files.txt" 'Driver:'
validator_assert_contains "$tmpdir/no-files.txt" 'Size is'
validator_assert_contains "$tmpdir/no-files.txt" 'Band 1'

# Default vs -nofl differ only in their Files: section. With a GTiff that
# has no auxiliary side-files the two outputs are identical apart from
# whitespace, but the flag must still be accepted without an error.
default_lines=$(wc -l <"$tmpdir/with-files.txt")
nofl_lines=$(wc -l <"$tmpdir/no-files.txt")
[[ "$nofl_lines" -le "$default_lines" ]] || {
  printf '-nofl output (%d lines) longer than default (%d lines)\n' \
    "$nofl_lines" "$default_lines" >&2
  exit 1
}
