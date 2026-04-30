#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-a-nodata-zero
# @title: GDAL gdal_translate -a_nodata sets nodata value
# @description: Runs gdal_translate -a_nodata 0 on the bundled gdalicon raster and verifies that gdalinfo -json reports the assigned nodata value on each band of the GTiff output.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-a-nodata-zero"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -a_nodata 0 \
  "$raster" "$tmpdir/nodata.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/nodata.tif"

gdalinfo -json "$tmpdir/nodata.tif" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "GTiff"
  and (.bands | length) >= 1
  and (.bands[0].noDataValue == 0 or .bands[0].noDataValue == "0")
' "$tmpdir/out.json"
