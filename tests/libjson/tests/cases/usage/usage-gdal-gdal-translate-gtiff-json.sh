#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-gtiff-json
# @title: GDAL gdal_translate GTiff JSON metadata
# @description: Converts the bundled gdalicon PNG to a GeoTIFF with gdal_translate and verifies that gdalinfo -json reports the GTiff driver and matching raster size.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-gtiff-json"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff "$raster" "$tmpdir/icon.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/icon.tif"

gdalinfo -json "$tmpdir/icon.tif" >"$tmpdir/out.json"
jq -e '.driverShortName == "GTiff" and (.size | length == 2) and .size[0] > 0 and .size[1] > 0' "$tmpdir/out.json"
