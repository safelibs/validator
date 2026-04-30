#!/usr/bin/env bash
# @testcase: usage-gdal-gdalwarp-dstnodata
# @title: GDAL gdalwarp -dstnodata setting
# @description: Reprojects a synthetic EPSG:4326 raster to itself with gdalwarp -dstnodata 0 and verifies that gdalinfo -json reports a NoDataValue of 0 on at least one output band.
# @timeout: 240
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalwarp-dstnodata"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -1 1 1 -1 \
  "$raster" "$tmpdir/src.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/src.tif"

gdalwarp -t_srs EPSG:4326 -dstnodata 0 \
  "$tmpdir/src.tif" "$tmpdir/dst.tif" >"$tmpdir/warp.log" 2>&1
validator_require_file "$tmpdir/dst.tif"

gdalinfo -json "$tmpdir/dst.tif" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "GTiff"
  and (.bands | length) >= 1
  and any(
    .bands[];
    (.noDataValue? // empty) | tonumber == 0
  )
' "$tmpdir/out.json"
