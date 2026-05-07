#!/usr/bin/env bash
# @testcase: usage-gdal-r12-gdalinfo-json-driver-short-name-png
# @title: GDAL gdalinfo JSON .driverShortName equals "PNG" with .files including the PNG path
# @description: Runs gdalinfo -json on the bundled gdalicon PNG and verifies the json-c emitted .driverShortName is "PNG" and .files is a non-empty array whose first entry ends with .png.
# @timeout: 180
# @tags: usage, gdal, json, driver
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
cp "$raster" "$tmpdir/icon.png"

gdalinfo -json "$tmpdir/icon.png" >"$tmpdir/out.json"
jq -e '
  (.driverShortName == "PNG")
  and (.files | type == "array")
  and (.files | length >= 1)
  and (.files[0] | endswith(".png"))
' "$tmpdir/out.json"
