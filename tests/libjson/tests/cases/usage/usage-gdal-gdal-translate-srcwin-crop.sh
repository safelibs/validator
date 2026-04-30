#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-srcwin-crop
# @title: GDAL gdal_translate -srcwin pixel crop
# @description: Crops a sub-window of the bundled gdalicon raster with gdal_translate -srcwin in pixel coordinates and verifies that gdalinfo -json reports the requested width and height on the resulting GeoTIFF.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-srcwin-crop"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdalinfo -json "$raster" >"$tmpdir/src.json"
src_w=$(jq -e '.size[0]' "$tmpdir/src.json")
src_h=$(jq -e '.size[1]' "$tmpdir/src.json")
[[ "$src_w" -ge 8 && "$src_h" -ge 8 ]] || {
  printf 'gdalicon source too small: %sx%s\n' "$src_w" "$src_h" >&2
  exit 1
}

# Crop a fixed 8x8 pixel window starting at (2, 2). The chosen offset/size
# fits inside any reasonable gdalicon build.
gdal_translate -of GTiff -srcwin 2 2 8 8 \
  "$raster" "$tmpdir/crop.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/crop.tif"

gdalinfo -json "$tmpdir/crop.tif" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "GTiff"
  and .size[0] == 8
  and .size[1] == 8
' "$tmpdir/out.json"
