#!/usr/bin/env bash
# @testcase: usage-gdal-gdaladdo-overviews
# @title: GDAL gdaladdo average overviews
# @description: Adds 2x and 4x overviews to a synthesized GeoTIFF with gdaladdo -r average and verifies that gdalinfo -json reports overview entries on the first band.
# @timeout: 240
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdaladdo-overviews"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -1 1 1 -1 \
  "$raster" "$tmpdir/src.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/src.tif"

gdaladdo -r average "$tmpdir/src.tif" 2 4 >"$tmpdir/addo.log" 2>&1

gdalinfo -json "$tmpdir/src.tif" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "GTiff"
  and (.bands | length) >= 1
  and ((.bands[0].overviews // []) | length) >= 2
  and all(.bands[0].overviews[]; (.size // []) | length == 2)
' "$tmpdir/out.json"
