#!/usr/bin/env bash
# @testcase: usage-gdal-r14-gdalinfo-json-stats-min-max-bounded-byte
# @title: GDAL gdalinfo -stats JSON .bands[0].minimum/maximum lie within [0, 255]
# @description: Runs gdalinfo -json -stats on the bundled gdalicon PNG and verifies the json-c emitted .bands[0].minimum and .bands[0].maximum are both numbers within the documented Byte data type range [0, 255] with minimum less than or equal to maximum.
# @timeout: 180
# @tags: usage, gdal, json, stats
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
cp "$raster" "$tmpdir/icon.png"

gdalinfo -json -stats "$tmpdir/icon.png" >"$tmpdir/out.json" 2>"$tmpdir/err"
jq -e '
  (.bands[0].minimum | type == "number")
  and (.bands[0].maximum | type == "number")
  and (.bands[0].minimum >= 0) and (.bands[0].minimum <= 255)
  and (.bands[0].maximum >= 0) and (.bands[0].maximum <= 255)
  and (.bands[0].minimum <= .bands[0].maximum)
' "$tmpdir/out.json"
