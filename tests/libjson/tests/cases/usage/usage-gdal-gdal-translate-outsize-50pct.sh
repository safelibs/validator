#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-outsize-50pct
# @title: GDAL gdal_translate -outsize 50% downscale
# @description: Downscales the bundled gdalicon PNG to 50% width and height with gdal_translate -outsize and verifies the gdalinfo -json reported size matches the halved source dimensions.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-outsize-50pct"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdalinfo -json "$raster" >"$tmpdir/src.json"
src_w=$(jq -e '.size[0]' "$tmpdir/src.json")
src_h=$(jq -e '.size[1]' "$tmpdir/src.json")
expected_w=$(( src_w / 2 ))
expected_h=$(( src_h / 2 ))

gdal_translate -of GTiff -outsize 50% 50% "$raster" "$tmpdir/half.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/half.tif"

gdalinfo -json "$tmpdir/half.tif" >"$tmpdir/out.json"
jq -e --argjson w "$expected_w" --argjson h "$expected_h" '
  .driverShortName == "GTiff"
  and .size[0] == $w
  and .size[1] == $h
' "$tmpdir/out.json"
