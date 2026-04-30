#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-co-compress-deflate
# @title: GDAL gdal_translate GTiff DEFLATE compression
# @description: Encodes the bundled gdalicon raster as GTiff with -co COMPRESSION=DEFLATE and verifies the IMAGE_STRUCTURE metadata reports DEFLATE in gdalinfo -json output.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-co-compress-deflate"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -co COMPRESS=DEFLATE \
  "$raster" "$tmpdir/deflate.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/deflate.tif"

gdalinfo -json "$tmpdir/deflate.tif" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "GTiff"
  and (
    [.. | objects | .COMPRESSION? // empty | strings]
    | any(. == "DEFLATE")
  )
' "$tmpdir/out.json"
