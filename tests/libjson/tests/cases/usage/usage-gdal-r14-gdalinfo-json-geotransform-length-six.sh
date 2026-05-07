#!/usr/bin/env bash
# @testcase: usage-gdal-r14-gdalinfo-json-geotransform-length-six
# @title: GDAL gdalinfo JSON .geoTransform is a 6-element numeric affine vector
# @description: Translates the bundled gdalicon PNG to a GeoTIFF with a known affine through -a_ullr and verifies gdalinfo -json (json-c serialised) reports a .geoTransform array of length exactly 6 whose entries are all numbers, confirming the documented affine transform shape.
# @timeout: 180
# @tags: usage, gdal, json, geotransform
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -180 90 180 -90 \
  "$raster" "$tmpdir/out.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/out.tif"

gdalinfo -json "$tmpdir/out.tif" >"$tmpdir/out.json"
jq -e '
  (.geoTransform | type == "array")
  and (.geoTransform | length == 6)
  and (.geoTransform | all(type == "number"))
' "$tmpdir/out.json"
