#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-band-select
# @title: GDAL gdal_translate single-band selection
# @description: Selects only the first band of the bundled gdalicon raster with gdal_translate -b 1 and verifies that gdalinfo -json reports a one-band GTiff output.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-band-select"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -b 1 \
  "$raster" "$tmpdir/band1.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/band1.tif"

gdalinfo -json "$tmpdir/band1.tif" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "GTiff"
  and (.bands | length) == 1
  and (.size[0] // 0) > 0
  and (.size[1] // 0) > 0
' "$tmpdir/out.json"
