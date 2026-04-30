#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-jpeg-json
# @title: GDAL gdal_translate JPEG JSON metadata
# @description: Converts the bundled gdalicon PNG to a JPEG with gdal_translate and verifies that gdalinfo -json reports the JPEG driver on the rewritten raster.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-jpeg-json"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of JPEG -b 1 -b 2 -b 3 "$raster" "$tmpdir/icon.jpg" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/icon.jpg"

gdalinfo -json "$tmpdir/icon.jpg" >"$tmpdir/out.json"
jq -e '.driverShortName == "JPEG" and (.bands | length) >= 1' "$tmpdir/out.json"
