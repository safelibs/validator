#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-json-geotransform
# @title: GDAL gdalinfo JSON geoTransform array
# @description: Stamps a known affine geotransform onto the bundled gdalicon raster and verifies that gdalinfo -json emits a 6-element geoTransform array whose origin and pixel-size entries match the values supplied via -a_ullr.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalinfo-json-geotransform"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

# 32x32 image stamped over [-1,1]x[-1,1] gives pixel size 0.0625 (= 2/32).
gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -1 1 1 -1 \
  "$raster" "$tmpdir/icon.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/icon.tif"

gdalinfo -json "$tmpdir/icon.tif" >"$tmpdir/out.json"
jq -e '
  (.geoTransform | type == "array")
  and (.geoTransform | length == 6)
  and (.geoTransform[0] == -1.0)
  and (.geoTransform[3] == 1.0)
  and (.geoTransform[1] == 0.0625)
  and (.geoTransform[5] == -0.0625)
' "$tmpdir/out.json"
