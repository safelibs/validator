#!/usr/bin/env bash
# @testcase: usage-gdal-r12-gdalinfo-json-size-matches-icon
# @title: GDAL gdalinfo JSON .size equals [32, 32] for the bundled gdalicon
# @description: Runs gdalinfo -json on the bundled gdalicon PNG and verifies the json-c serialised .size array equals [32, 32], matching the documented icon dimensions.
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
