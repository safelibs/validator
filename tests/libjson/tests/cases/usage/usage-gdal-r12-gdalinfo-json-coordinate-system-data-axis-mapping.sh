#!/usr/bin/env bash
# @testcase: usage-gdal-r12-gdalinfo-json-coordinate-system-data-axis-mapping
# @title: GDAL gdalinfo JSON coordinateSystem.dataAxisToSRSAxisMapping is a non-empty array
# @description: Translates the bundled gdalicon PNG to a GeoTIFF with EPSG:4326 and verifies gdalinfo -json (json-c serialised) reports a coordinateSystem.dataAxisToSRSAxisMapping array of length 2 with positive integer entries.
# @timeout: 180
# @tags: usage, gdal, json, srs
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
  (.coordinateSystem.dataAxisToSRSAxisMapping | type == "array")
  and (.coordinateSystem.dataAxisToSRSAxisMapping | length == 2)
  and (.coordinateSystem.dataAxisToSRSAxisMapping | all(. > 0))
' "$tmpdir/out.json"
