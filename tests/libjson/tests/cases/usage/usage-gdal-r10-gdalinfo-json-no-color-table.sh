#!/usr/bin/env bash
# @testcase: usage-gdal-r10-gdalinfo-json-no-color-table
# @title: GDAL gdalinfo JSON omits color table for greyscale tiff
# @description: Converts the bundled gdalicon raster into a single-band Byte GeoTIFF via gdal_translate -b 1 and verifies that gdalinfo -json (json-c serialised) reports a single Gray-interpretation band with no colorTable key.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -b 1 -ot Byte \
  "$raster" "$tmpdir/gray.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/gray.tif"

gdalinfo -json "$tmpdir/gray.tif" >"$tmpdir/out.json"
jq -e '
  ((.bands | length) == 1)
  and (.bands[0].colorInterpretation == "Gray")
  and ((.bands[0] | has("colorTable")) | not)
' "$tmpdir/out.json"
