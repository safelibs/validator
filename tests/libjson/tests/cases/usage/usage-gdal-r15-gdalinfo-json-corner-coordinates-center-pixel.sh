#!/usr/bin/env bash
# @testcase: usage-gdal-r15-gdalinfo-json-corner-coordinates-center-pixel
# @title: GDAL gdalinfo JSON cornerCoordinates.center equals [16,16] for the icon
# @description: Runs gdalinfo -json on the bundled gdalicon PNG and verifies the json-c emitted cornerCoordinates.center array equals exactly [16, 16], the documented half-extent of the 32x32 raster in pixel coordinates.
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
jq -e '.cornerCoordinates.center == [16, 16]' "$tmpdir/out.json"
