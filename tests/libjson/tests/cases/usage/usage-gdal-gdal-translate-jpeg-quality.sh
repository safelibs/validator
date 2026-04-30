#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-jpeg-quality
# @title: GDAL gdal_translate JPEG quality option
# @description: Encodes the bundled gdalicon raster to JPEG with gdal_translate -co QUALITY=50 and verifies the resulting file reports the JPEG driver via gdalinfo -json.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-jpeg-quality"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of JPEG -b 1 -b 2 -b 3 -co QUALITY=50 \
  "$raster" "$tmpdir/icon.jpg" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/icon.jpg"

# Sanity-check the file is a real JPEG byte stream (FF D8 FF magic).
file "$tmpdir/icon.jpg" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'JPEG'

gdalinfo -json "$tmpdir/icon.jpg" >"$tmpdir/out.json"
jq -e '.driverShortName == "JPEG" and (.size[0] // 0) > 0 and (.bands | length) >= 1' "$tmpdir/out.json"
