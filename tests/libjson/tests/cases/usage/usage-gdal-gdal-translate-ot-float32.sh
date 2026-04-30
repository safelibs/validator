#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-ot-float32
# @title: GDAL gdal_translate -ot Float32 type conversion
# @description: Converts the bundled gdalicon raster to a Float32 GeoTIFF with gdal_translate -ot Float32 and verifies that gdalinfo -json reports Float32 as the band data type.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-ot-float32"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -ot Float32 -b 1 \
  "$raster" "$tmpdir/f32.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/f32.tif"

gdalinfo -json "$tmpdir/f32.tif" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "GTiff"
  and (.bands | length) >= 1
  and .bands[0].type == "Float32"
' "$tmpdir/out.json"
