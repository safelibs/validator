#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-json-coordsys-axis-mapping
# @title: GDAL gdalinfo JSON coordinate system axis mapping
# @description: Tags the bundled gdalicon raster with EPSG:3857 and verifies that gdalinfo -json emits a coordinateSystem object whose dataAxisToSRSAxisMapping is the expected [1,2] array and whose WKT begins with the projected CRS keyword.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalinfo-json-coordsys-axis-mapping"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -a_srs EPSG:3857 -a_ullr 0 0 1000 -1000 \
  "$raster" "$tmpdir/proj.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/proj.tif"

gdalinfo -json "$tmpdir/proj.tif" >"$tmpdir/out.json"
jq -e '
  (.coordinateSystem.dataAxisToSRSAxisMapping | type == "array")
  and (.coordinateSystem.dataAxisToSRSAxisMapping == [1, 2])
  and ((.coordinateSystem.wkt // "") | startswith("PROJCRS"))
' "$tmpdir/out.json"
