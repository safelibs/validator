#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-json-extent-polygon
# @title: GDAL gdalinfo JSON extent polygon
# @description: Stamps a CRS+geotransform onto the bundled gdalicon raster, then runs gdalinfo -json and verifies the JSON output exposes a wgs84Extent Polygon geometry with a closed coordinate ring rendered via json-c.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalinfo-json-extent-polygon"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

# Stamp WGS84 CRS and bounding box so gdalinfo emits a populated extent polygon.
gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -1 1 1 -1 \
  "$raster" "$tmpdir/icon.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/icon.tif"

gdalinfo -json "$tmpdir/icon.tif" >"$tmpdir/out.json"
jq -e '
  .wgs84Extent.type == "Polygon"
  and (.wgs84Extent.coordinates | type == "array")
  and ((.wgs84Extent.coordinates[0] // []) | length >= 4)
  and (.wgs84Extent.coordinates[0][0] == .wgs84Extent.coordinates[0][-1])
' "$tmpdir/out.json"
