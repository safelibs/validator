#!/usr/bin/env bash
# @testcase: usage-gdal-r13-gdalinfo-json-corner-coordinates-pixel-bounds
# @title: GDAL gdalinfo JSON cornerCoordinates upperLeft is [0,0] and lowerRight is [32,32]
# @description: Runs gdalinfo -json on the bundled gdalicon PNG (which has no SRS, so corner coordinates are reported in raster pixel space) and verifies the json-c emitted upperLeft equals [0,0] and lowerRight equals [32,32], matching the icon's 32x32 pixel extent.
# @timeout: 180
# @tags: usage, gdal, json, corners
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
  (.cornerCoordinates.upperLeft == [0, 0])
  and (.cornerCoordinates.lowerRight == [32, 32])
' "$tmpdir/out.json"
