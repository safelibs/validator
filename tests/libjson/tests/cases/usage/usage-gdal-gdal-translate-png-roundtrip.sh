#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-png-roundtrip
# @title: GDAL gdal_translate PNG round-trip
# @description: Round-trips the bundled gdalicon raster through PNG and back to GeoTIFF with gdal_translate, verifying gdalinfo -json reports the PNG driver on the intermediate output and the GTiff driver on the round-tripped result.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-png-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of PNG "$raster" "$tmpdir/icon.png" >"$tmpdir/translate-png.log" 2>&1
validator_require_file "$tmpdir/icon.png"

gdalinfo -json "$tmpdir/icon.png" >"$tmpdir/png.json"
jq -e '.driverShortName == "PNG" and (.size[0] // 0) > 0 and (.size[1] // 0) > 0' "$tmpdir/png.json"

gdal_translate -of GTiff "$tmpdir/icon.png" "$tmpdir/icon.tif" >"$tmpdir/translate-tif.log" 2>&1
validator_require_file "$tmpdir/icon.tif"

gdalinfo -json "$tmpdir/icon.tif" >"$tmpdir/tif.json"
jq -e '.driverShortName == "GTiff" and (.bands | length) >= 1' "$tmpdir/tif.json"
