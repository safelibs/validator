#!/usr/bin/env bash
# @testcase: usage-gdal-r14-gdalinfo-json-size-array-pixel-dimensions
# @title: GDAL gdalinfo JSON .size equals [32, 32] for the bundled icon
# @description: Runs gdalinfo -json on the bundled gdalicon PNG and verifies the json-c emitted .size array equals exactly [32, 32], the documented [width, height] pair of the icon raster.
# @timeout: 180
# @tags: usage, gdal, json, size
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
cp "$raster" "$tmpdir/icon.png"

gdalinfo -json "$tmpdir/icon.png" >"$tmpdir/out.json"
jq -e '.size == [32, 32]' "$tmpdir/out.json"
