#!/usr/bin/env bash
# @testcase: usage-gdal-r11-gdalinfo-json-image-structure-interleave-pixel
# @title: GDAL gdalinfo JSON metadata IMAGE_STRUCTURE.INTERLEAVE equals PIXEL for PNG icon
# @description: Runs gdalinfo -json on the bundled gdalicon PNG and verifies the json-c emitted .metadata IMAGE_STRUCTURE domain carries an INTERLEAVE key whose value is exactly "PIXEL".
# @timeout: 180
# @tags: usage, gdal, json, metadata
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
cp "$raster" "$tmpdir/icon.png"

gdalinfo -json "$tmpdir/icon.png" >"$tmpdir/out.json"
jq -e '.metadata.IMAGE_STRUCTURE.INTERLEAVE == "PIXEL"' "$tmpdir/out.json"
