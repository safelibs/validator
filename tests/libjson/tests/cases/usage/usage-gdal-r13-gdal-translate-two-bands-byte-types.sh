#!/usr/bin/env bash
# @testcase: usage-gdal-r13-gdal-translate-two-bands-byte-types
# @title: GDAL gdal_translate -b 1 -b 2 emits a 2-band GTiff whose .bands[].type is "Byte"
# @description: Runs gdal_translate with explicit -b 1 -b 2 band selection on the bundled gdalicon PNG to a GeoTIFF and verifies gdalinfo -json (json-c serialised) reports exactly two bands whose .bands[].type values are both the literal string "Byte".
# @timeout: 180
# @tags: usage, gdal, json, bands
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -b 1 -b 2 \
  "$raster" "$tmpdir/two.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/two.tif"

gdalinfo -json "$tmpdir/two.tif" >"$tmpdir/out.json"
jq -e '
  (.bands | length == 2)
  and ([.bands[].type] == ["Byte", "Byte"])
' "$tmpdir/out.json"
